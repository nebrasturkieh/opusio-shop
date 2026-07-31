-- =============================================================
-- Add server-side shipping-address validation to place_order_atomic.
--
-- Base: sql/harden_place_order_atomic.sql (the current authoritative,
-- deployed definition — NOT the older sql/place_order_atomic_v3.sql,
-- so the advisory-lock concurrency hardening is not lost). This patch
-- uses CREATE OR REPLACE FUNCTION with the exact existing signature
-- public.place_order_atomic(jsonb, jsonb, uuid, text) — it does not drop
-- the function and does not introduce a second overload.
--
-- Confirmed shipping contract (shop_frontend/src/views/CheckoutView.vue,
-- shop_frontend/src/stores/orders.js):
--   { full_name: string, phone: string, address: string, city: string,
--     country: string }
-- full_name/address/city/country are validated client-side as required,
-- non-empty (trimmed) strings; phone has no client-side validation and
-- may be an empty string. Nothing in the repository suggests maximum
-- lengths, country enums, phone formats, or normalization — none are
-- added here.
--
-- What changed vs. sql/harden_place_order_atomic.sql:
--   A new "── 3b. Shipping address validation ──" step is added,
--   positioned:
--     • AFTER the advisory lock (1d) and the existing-order idempotency
--       lookup (2) — so a repeated call with an already-used idempotency
--       key still returns the prior order immediately, before shipping
--       is ever inspected, exactly as before.
--     • AFTER the empty-cart guard (3) — preserving its existing
--       precedence (EMPTY_ORDER still raised first for an empty cart,
--       regardless of shipping payload).
--     • BEFORE item aggregation (4), catalogue row locking/validation
--       (5), stock checking, stock decrement, and the order insert (8) —
--       so malformed shipping data is rejected before any catalogue
--       lock is taken or any row is mutated.
--   Rejects with `raise exception 'INVALID_SHIPPING_ADDRESS';` for: a
--   SQL NULL or JSON null p_shipping; a non-object top-level JSON value;
--   a missing/non-string/blank required field (full_name, address, city,
--   country); or a present `phone` key whose JSON type is not `string`.
--   Accepts: all four required fields as non-blank strings, with `phone`
--   absent, `phone: ""`, or any other unknown extra keys.
--
-- Everything else — parameter names/order, `p_currency default 'EUR'`,
-- return type/response shape, SECURITY DEFINER, `set search_path to
-- public, pg_temp`, schema-qualified public.orders/public.products/
-- public.product_variants, the auth.uid()/currency/idempotency-key
-- checks, the advisory lock, the existing-order lookup, the empty-cart
-- guard, duplicate-item aggregation, deterministic ascending-variant_id
-- row locking, the active-product/active-variant `is distinct from true`
-- checks, stock validation/decrement, bigint monetary math, the order
-- insert, the 'pending' status, the response shape, and all exception/
-- rollback behavior — is preserved unchanged from
-- sql/harden_place_order_atomic.sql. No table, index, constraint, RLS
-- policy, unrelated grant, catalogue behavior, image, stock-restoration,
-- cancellation, refund, or order-status logic is touched, and no
-- frontend file is changed by this patch.
-- =============================================================

begin;

create or replace function public.place_order_atomic(
  p_items            jsonb,
  p_shipping         jsonb,
  p_idempotency_key  uuid,
  p_currency         text default 'EUR'
)
returns jsonb
language plpgsql
security definer
set search_path to public, pg_temp
as $$
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
$$;

-- Reassert the confirmed execution boundary (anon EXECUTE=false,
-- authenticated EXECUTE=true) after replacement.
revoke all on function public.place_order_atomic(jsonb, jsonb, uuid, text)
  from public;

revoke all on function public.place_order_atomic(jsonb, jsonb, uuid, text)
  from anon;

grant execute on function public.place_order_atomic(jsonb, jsonb, uuid, text)
  to authenticated, service_role;

commit;
