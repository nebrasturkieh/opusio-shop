-- =============================================================
-- Harden place_order_atomic (confirmed live signature:
-- public.place_order_atomic(jsonb, jsonb, uuid, text), owner postgres,
-- SECURITY DEFINER, search_path=public, anon EXECUTE=false,
-- authenticated EXECUTE=true — no other live overloads).
--
-- This patch uses CREATE OR REPLACE FUNCTION with the exact existing
-- signature — it does not drop the function and does not introduce a
-- second overload. All existing behavior is preserved except for the
-- specific hardening changes below:
--
--   1. search_path hardened to `public, pg_temp` (was `public`).
--   2. Application tables schema-qualified as public.orders,
--      public.products, public.product_variants.
--   3. A transaction-level advisory lock, derived from the idempotency
--      key, is acquired immediately after the auth/currency/idempotency-
--      key-presence checks and BEFORE the existing-order lookup and any
--      stock mutation. Two concurrent calls with the same idempotency
--      key now serialize: the second caller blocks on the lock until the
--      first transaction commits or rolls back, then repeats the
--      existing-order lookup and finds the row the first call inserted,
--      returning it with idempotent = true instead of processing stock a
--      second time. (No unique_violation catch is added around the
--      final insert — that would only guard the insert itself and could
--      still leave an earlier stock decrement applied twice; the
--      advisory lock instead prevents two concurrent calls from ever
--      reaching the stock-processing loop for the same key at the same
--      time.)
--   4. Monetary multiplication (line_total_cents and the running
--      v_total_cents accumulation) is performed with explicit bigint
--      operands so the multiplication itself cannot overflow integer
--      range before widening.
--   5. Active-flag checks use `is distinct from true` rather than
--      `is false`, since product_variants.is_active is confirmed
--      `not null` (create_product_variants.sql) but products.is_active
--      has no tracked NOT NULL constraint in this repository (products'
--      CREATE TABLE is not tracked) — `is distinct from true` treats a
--      null value as "not active" (safe default) instead of silently
--      passing an `is false` check that a null would fail to trigger.
--   6. The confirmed execution boundary is reasserted after replacement:
--      EXECUTE revoked from public/anon, granted to authenticated and
--      service_role only.
--
-- Unchanged (preserved exactly): parameter order and names, the
-- p_currency text default 'EUR' default, the jsonb return type and
-- response shape ({id, total_cents, idempotent}), SECURITY DEFINER,
-- server-derived auth.uid() identity, database-derived pricing, the
-- active product/variant checks (semantics only made null-safe, not
-- weakened), duplicate-item aggregation by variant_id, the stable
-- ascending variant_id lock order, stock check/decrement semantics, the
-- 'pending' initial order status, and all existing exception/rollback
-- behavior for malformed quantities, missing variants, inactive
-- catalogue rows, insufficient stock, and failed inserts. No table,
-- index, RLS policy, storage policy, order-status set, cancellation,
-- refund, or stock-restoration logic is touched. No frontend file is
-- changed in this patch.
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
