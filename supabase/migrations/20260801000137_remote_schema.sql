-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres REVOKE ALL ON ROUTINES FROM PUBLIC;

DROP EXTENSION pg_net;

DROP EXTENSION pg_graphql;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES FROM anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE UPDATE ON SEQUENCES FROM anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES FROM authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE UPDATE ON SEQUENCES FROM authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES FROM service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE UPDATE ON SEQUENCES FROM service_role;

CREATE FUNCTION public.admin_update_order_status (
  p_order_id uuid,
  p_status   text
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare
  v_allowed text[] := array[
    'pending',
    'paid',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded'
  ];
  v_order   orders%rowtype;
begin
  -- ── Auth check ─────────────────────────────────────────────────────────
  if not public.is_admin() then
    raise exception 'Unauthorized' using errcode = 'insufficient_privilege';
  end if;

  -- ── Validate status ─────────────────────────────────────────────────────
  if p_status is null or not (p_status = any(v_allowed)) then
    raise exception 'Invalid status %. Allowed: %', p_status, array_to_string(v_allowed, ', ')
      using errcode = 'invalid_parameter_value';
  end if;

  -- ── Update only status + updated_at ────────────────────────────────────
  update orders
  set
    status     = p_status,
    updated_at = now()
  where id = p_order_id
  returning * into v_order;

  if not found then
    raise exception 'Order % not found', p_order_id
      using errcode = 'no_data_found';
  end if;

  -- ── Return updated order ────────────────────────────────────────────────
  return jsonb_build_object(
    'id',         v_order.id,
    'status',     v_order.status,
    'updated_at', v_order.updated_at
  );
end;
$function$;

REVOKE ALL ON FUNCTION public.admin_update_order_status(uuid, text) FROM PUBLIC;

GRANT ALL ON FUNCTION public.admin_update_order_status(uuid, text) TO authenticated;

GRANT ALL ON FUNCTION public.admin_update_order_status(uuid, text) TO service_role;

CREATE FUNCTION public.is_admin()
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
  select exists (
    select 1 from profiles
    where id = auth.uid()
      and role = 'admin'
  )
$function$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;

GRANT ALL ON FUNCTION public.is_admin() TO authenticated;

GRANT ALL ON FUNCTION public.is_admin() TO service_role;

CREATE FUNCTION public.place_order_atomic (
  p_items           jsonb,
  p_shipping        jsonb,
  p_idempotency_key uuid,
  p_currency        text  DEFAULT 'EUR'::text
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'pg_temp'
  AS $function$
declare
  v_user_id       uuid;
  v_order_id      uuid;
  v_total_cents   bigint := 0;
  v_existing_id   uuid;

  -- per-item working variables
  v_vid           bigint;
  v_qty           integer;
  v_price_cents   integer;
  v_stock         integer;
  v_is_active      boolean;
  v_product_active boolean;
  v_product_id     bigint;
  v_product_name   text;
  v_sku           text;
  v_mat_color     text;
  v_size          text;
  v_finish        text;
  v_stone         text;
  v_image_url     text;

  v_snapshot      jsonb := '[]'::jsonb;
  v_snapshot_item jsonb;

  -- pre-aggregated items (sum quantities for duplicate variant_ids)
  v_agg           jsonb;
begin

  -- ── 1. Auth check ──────────────────────────────────────────────────────
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED';
  end if;

  -- ── 1b. Currency validation ───────────────────────────────────────────
  if p_currency is distinct from 'EUR' then
    raise exception 'UNSUPPORTED_CURRENCY:%', p_currency;
  end if;

  -- ── 1c. Idempotency key presence ─────────────────────────────────────
  if p_idempotency_key is null then
    raise exception 'MISSING_IDEMPOTENCY_KEY';
  end if;

  -- ── 1d. Serialize concurrent requests for the same idempotency key ────
  -- Transaction-scoped advisory lock: a second concurrent call with the
  -- same key blocks here until the first call's transaction commits or
  -- rolls back, then proceeds to repeat the existing-order lookup below
  -- before touching stock.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_idempotency_key::text, 0)
  );

  -- ── 2. Idempotency check ───────────────────────────────────────────────
  select id into v_existing_id
    from public.orders
   where idempotency_key = p_idempotency_key
     and user_id = v_user_id
   limit 1;

  if v_existing_id is not null then
    select jsonb_build_object(
      'id',           o.id,
      'total_cents',  o.total_cents,
      'idempotent',   true
    ) into v_snapshot_item
    from public.orders o where o.id = v_existing_id;
    return v_snapshot_item;
  end if;

  -- ── 3. Empty cart guard ────────────────────────────────────────────────
  if p_items is null
     or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_ORDER';
  end if;

  -- ── 3b. Shipping address validation ────────────────────────────────────
  -- Runs after the advisory lock, the existing-order lookup, and the
  -- empty-cart guard, but before any item aggregation, catalogue locking,
  -- stock check/mutation, or insert — malformed shipping data cannot
  -- cause a stock decrement or a partial/incorrect order.
  if p_shipping is null
     or pg_catalog.jsonb_typeof(p_shipping) is distinct from 'object'
     or pg_catalog.jsonb_typeof(p_shipping->'full_name') is distinct from 'string'
     or coalesce(pg_catalog.btrim(p_shipping->>'full_name'), '') = ''
     or pg_catalog.jsonb_typeof(p_shipping->'address') is distinct from 'string'
     or coalesce(pg_catalog.btrim(p_shipping->>'address'), '') = ''
     or pg_catalog.jsonb_typeof(p_shipping->'city') is distinct from 'string'
     or coalesce(pg_catalog.btrim(p_shipping->>'city'), '') = ''
     or pg_catalog.jsonb_typeof(p_shipping->'country') is distinct from 'string'
     or coalesce(pg_catalog.btrim(p_shipping->>'country'), '') = ''
     or (
       p_shipping ? 'phone'
       and pg_catalog.jsonb_typeof(p_shipping->'phone') is distinct from 'string'
     ) then
    raise exception 'INVALID_SHIPPING_ADDRESS';
  end if;

  -- ── 4. Pre-aggregate by variant_id (sum quantities for duplicates) ─────
  select jsonb_agg(agg_row) into v_agg
  from (
    select
      (elem->>'variant_id')::bigint                          as variant_id,
      sum((elem->>'quantity')::integer)                      as quantity
    from jsonb_array_elements(p_items) as elem
    group by (elem->>'variant_id')::bigint
    order by 1  -- stable order for deadlock prevention
  ) agg_row;

  -- ── 5. Validate, lock, and compute total ───────────────────────────────
  for v_vid, v_qty in
    select
      (row_val->>'variant_id')::bigint,
      (row_val->>'quantity')::integer
    from jsonb_array_elements(v_agg) as row_val
    order by (row_val->>'variant_id')::bigint  -- deadlock-safe order
  loop

    if v_vid is null or v_qty is null or v_qty <= 0 then
      raise exception 'INVALID_QUANTITY:%', v_vid;
    end if;

    -- Lock the variant row
    select
      pv.is_active,
      pv.price_cents,
      pv.stock_quantity,
      pv.sku,
      pv.material_color,
      pv.size,
      pv.finish,
      pv.stone,
      coalesce(pv.image_url, p.image_url, p.images->>0),
      p.id,
      p.name,
      p.is_active
    into
      v_is_active,
      v_price_cents,
      v_stock,
      v_sku,
      v_mat_color,
      v_size,
      v_finish,
      v_stone,
      v_image_url,
      v_product_id,
      v_product_name,
      v_product_active
    from public.product_variants pv
    join public.products p on p.id = pv.product_id
    where pv.id = v_vid
    for update of pv;  -- lock variant only, not products

    if not found then
      raise exception 'VARIANT_NOT_FOUND:%', v_vid;
    end if;

    if v_is_active is distinct from true then
      raise exception 'VARIANT_UNAVAILABLE:%', v_vid;
    end if;

    if v_product_active is distinct from true then
      raise exception 'PRODUCT_UNAVAILABLE:%', v_product_id;
    end if;

    if v_price_cents is null then
      raise exception 'VARIANT_PRICE_MISSING:%', v_vid;
    end if;

    -- Stock check
    if v_stock is not null and v_stock < v_qty then
      raise exception 'INSUFFICIENT_STOCK:%', v_product_name;
    end if;

    -- ── 6. Decrement stock ───────────────────────────────────────────────
    update public.product_variants
       set stock_quantity = stock_quantity - v_qty
     where id = v_vid;

    -- ── 7. Build snapshot item ───────────────────────────────────────────
    v_snapshot_item := jsonb_build_object(
      'variant_id',       v_vid,
      'product_id',       v_product_id,
      'product_name',     v_product_name,
      'sku',              v_sku,
      'material_color',   v_mat_color,
      'size',             v_size,
      'finish',           v_finish,
      'stone',            v_stone,
      'image_url',        v_image_url,
      'quantity',         v_qty,
      'unit_price_cents', v_price_cents,
      'line_total_cents', v_price_cents::bigint * v_qty::bigint
    );

    v_snapshot    := v_snapshot || jsonb_build_array(v_snapshot_item);
    v_total_cents := v_total_cents + (v_price_cents::bigint * v_qty::bigint);

  end loop;

  -- ── 8. Insert order ────────────────────────────────────────────────────
  insert into public.orders (
    user_id,
    status,
    total_cents,
    currency,
    shipping_address,
    items_snapshot,
    idempotency_key
  ) values (
    v_user_id,
    'pending',
    v_total_cents,
    p_currency,
    p_shipping,
    v_snapshot,
    p_idempotency_key
  )
  returning id into v_order_id;

  -- ── 9. Return ──────────────────────────────────────────────────────────
  return jsonb_build_object(
    'id',          v_order_id,
    'total_cents', v_total_cents,
    'idempotent',  false
  );

end;
$function$;

REVOKE ALL ON FUNCTION public.place_order_atomic(jsonb, jsonb, uuid, text) FROM PUBLIC;

GRANT ALL ON FUNCTION public.place_order_atomic(jsonb, jsonb, uuid, text) TO authenticated;

GRANT ALL ON FUNCTION public.place_order_atomic(jsonb, jsonb, uuid, text) TO service_role;

CREATE FUNCTION public.set_updated_at()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

REVOKE ALL ON FUNCTION public.set_updated_at() FROM PUBLIC;

GRANT ALL ON FUNCTION public.set_updated_at() TO service_role;

CREATE TABLE public.cart_items (
  id               uuid                     DEFAULT gen_random_uuid() NOT NULL,
  user_id          uuid                     NOT NULL,
  quantity         integer                  DEFAULT 1 NOT NULL,
  product_snapshot jsonb                    NOT NULL,
  created_at       timestamp with time zone DEFAULT now() NOT NULL,
  updated_at       timestamp with time zone DEFAULT now() NOT NULL,
  variant_id       bigint
);

ALTER TABLE public.cart_items
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.cart_items
  ADD CONSTRAINT cart_items_pkey PRIMARY KEY (id);

ALTER TABLE public.cart_items
  ADD CONSTRAINT cart_items_quantity_check CHECK (quantity > 0);

ALTER TABLE public.cart_items
  ADD CONSTRAINT cart_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

GRANT DELETE, INSERT, SELECT, UPDATE ON public.cart_items TO authenticated;

GRANT ALL ON public.cart_items TO service_role;

CREATE UNIQUE INDEX cart_items_user_variant_unique ON public.cart_items (user_id, variant_id);

CREATE POLICY "Users manage own cart" ON public.cart_items
  USING ((auth.uid() = user_id));

CREATE TABLE public.orders (
  id               uuid                     DEFAULT gen_random_uuid() NOT NULL,
  user_id          uuid                     NOT NULL,
  status           text                     DEFAULT 'pending'::text NOT NULL,
  total_cents      bigint                   NOT NULL,
  currency         text                     DEFAULT 'EUR'::text NOT NULL,
  shipping_address jsonb                    NOT NULL,
  items_snapshot   jsonb                    NOT NULL,
  created_at       timestamp with time zone DEFAULT now() NOT NULL,
  updated_at       timestamp with time zone DEFAULT now() NOT NULL,
  idempotency_key  uuid
);

ALTER TABLE public.orders
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.orders
  ADD CONSTRAINT orders_idempotency_key_key UNIQUE (idempotency_key);

ALTER TABLE public.orders
  ADD CONSTRAINT orders_pkey PRIMARY KEY (id);

ALTER TABLE public.orders
  ADD CONSTRAINT orders_status_check
    CHECK (status = ANY (ARRAY['pending'::text, 'paid'::text, 'processing'::text, 'shipped'::text, 'delivered'::text, 'cancelled'::text, 'refunded'::text]));

ALTER TABLE public.orders
  ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

GRANT SELECT ON public.orders TO authenticated;

GRANT ALL ON public.orders TO service_role;

CREATE POLICY orders_admin_select ON public.orders
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE POLICY users_read_own_orders ON public.orders
  FOR SELECT
  TO authenticated
  USING ((( SELECT auth.uid() AS uid) = user_id));

CREATE TABLE public.product_variants (
  id             bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  product_id     bigint                   NOT NULL,
  material_color text,
  size           text,
  finish         text,
  stone          text,
  material_type  text,
  sku            text                     NOT NULL,
  price_cents    integer                  NOT NULL,
  stock_quantity integer                  DEFAULT 0 NOT NULL,
  image_url      text,
  weight_grams   numeric,
  width_mm       numeric,
  length_mm      numeric,
  is_active      boolean                  DEFAULT true NOT NULL,
  created_at     timestamp with time zone DEFAULT now() NOT NULL,
  updated_at     timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.product_variants
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.product_variants
  ADD CONSTRAINT product_variants_pkey PRIMARY KEY (id);

ALTER TABLE public.cart_items
  ADD CONSTRAINT cart_items_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.product_variants(id) ON DELETE CASCADE;

ALTER TABLE public.product_variants
  ADD CONSTRAINT product_variants_price_cents_check CHECK (price_cents >= 0);

ALTER TABLE public.product_variants
  ADD CONSTRAINT product_variants_stock_quantity_check CHECK (stock_quantity >= 0);

GRANT SELECT ON public.product_variants TO anon;

GRANT INSERT, SELECT, UPDATE ON public.product_variants TO authenticated;

GRANT ALL ON public.product_variants TO service_role;

CREATE UNIQUE INDEX product_variants_sku_key ON public.product_variants (sku);

CREATE TRIGGER product_variants_set_updated_at
  BEFORE UPDATE ON public.product_variants
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE POLICY product_variants_admin_insert ON public.product_variants
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY product_variants_admin_select ON public.product_variants
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE POLICY product_variants_admin_update ON public.product_variants
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE TABLE public.products (
  id          bigint                   GENERATED BY DEFAULT AS IDENTITY NOT NULL,
  created_at  timestamp with time zone DEFAULT now() NOT NULL,
  name        text                     NOT NULL,
  slug        text                     NOT NULL,
  description text,
  image_url   text                     NOT NULL,
  is_active   boolean                  DEFAULT true NOT NULL,
  images      jsonb,
  collection  text,
  category    text
);

CREATE POLICY product_variants_select_active ON public.product_variants
  FOR SELECT
  USING (((is_active = true) AND (EXISTS ( SELECT 1
   FROM public.products p
  WHERE ((p.id = product_variants.product_id) AND (p.is_active = true))))));

ALTER TABLE public.products
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.products
  ADD CONSTRAINT products_pkey PRIMARY KEY (id);

ALTER TABLE public.product_variants
  ADD CONSTRAINT product_variants_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

ALTER TABLE public.products
  ADD CONSTRAINT products_slug_key UNIQUE (slug);

GRANT SELECT ON public.products TO anon;

GRANT INSERT, SELECT, UPDATE ON public.products TO authenticated;

GRANT ALL ON public.products TO service_role;

CREATE POLICY products_admin_insert ON public.products
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY products_admin_select ON public.products
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE POLICY products_admin_update ON public.products
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY products_public_read ON public.products
  FOR SELECT
  USING ((is_active = true));

CREATE TABLE public.profiles (
  id         uuid                     NOT NULL,
  full_name  text,
  role       text                     DEFAULT 'user'::text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  phone      text,
  address    text,
  city       text,
  country    text
);

ALTER TABLE public.profiles
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check CHECK (role = ANY (ARRAY['user'::text, 'admin'::text]));

GRANT INSERT, SELECT, UPDATE ON public.profiles TO authenticated;

GRANT ALL ON public.profiles TO service_role;

CREATE POLICY profiles_admin_select ON public.profiles
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE POLICY profiles_insert_own ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (((( SELECT auth.uid() AS uid) = id) AND (role = 'user'::text)));

CREATE POLICY profiles_select_own ON public.profiles
  FOR SELECT
  USING ((auth.uid() = id));

CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE
  TO authenticated
  USING ((( SELECT auth.uid() AS uid) = id))
  WITH CHECK (((( SELECT auth.uid() AS uid) = id) AND (role =
CASE
    WHEN ( SELECT public.is_admin() AS is_admin) THEN 'admin'::text
    ELSE 'user'::text
END)));

CREATE TABLE public.variant_images (
  id         bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  variant_id bigint                   NOT NULL,
  image_url  text                     NOT NULL,
  alt_text   text,
  role       text,
  sort_order integer                  DEFAULT 0 NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.variant_images
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.variant_images
  ADD CONSTRAINT variant_images_pkey PRIMARY KEY (id);

ALTER TABLE public.variant_images
  ADD CONSTRAINT variant_images_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.product_variants(id) ON DELETE CASCADE;

GRANT SELECT ON public.variant_images TO anon;

GRANT DELETE, INSERT, SELECT, UPDATE ON public.variant_images TO authenticated;

GRANT ALL ON public.variant_images TO service_role;

CREATE INDEX variant_images_variant_id_sort_idx ON public.variant_images (variant_id, sort_order);

CREATE UNIQUE INDEX variant_images_variant_url_unique ON public.variant_images (variant_id, image_url);

CREATE POLICY variant_images_admin_all ON public.variant_images
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY variant_images_select_public ON public.variant_images
  FOR SELECT
  USING ((EXISTS ( SELECT 1
   FROM (public.product_variants pv
     JOIN public.products p ON ((p.id = pv.product_id)))
  WHERE ((pv.id = variant_images.variant_id) AND (pv.is_active = true) AND (p.is_active = true)))));

CREATE TABLE public.wishlist_items (
  id               uuid                     DEFAULT gen_random_uuid() NOT NULL,
  user_id          uuid                     NOT NULL,
  product_id       text                     NOT NULL,
  product_snapshot jsonb                    NOT NULL,
  created_at       timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.wishlist_items
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.wishlist_items
  ADD CONSTRAINT wishlist_items_pkey PRIMARY KEY (id);

ALTER TABLE public.wishlist_items
  ADD CONSTRAINT wishlist_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.wishlist_items
  ADD CONSTRAINT wishlist_items_user_id_product_id_key UNIQUE (user_id, product_id);

GRANT DELETE, INSERT, SELECT, UPDATE ON public.wishlist_items TO authenticated;

GRANT ALL ON public.wishlist_items TO service_role;

CREATE POLICY "Users manage own wishlist" ON public.wishlist_items
  USING ((auth.uid() = user_id));
