-- =============================================================
-- STEP 1: product_variants table
-- =============================================================
-- Run this AFTER exporting/backing up your current tables.
-- The existing products table columns (price_cents, stock_quantity,
-- material, etc.) are intentionally kept during the migration.
-- They will be removed in a later cleanup migration once the
-- frontend is fully switched to variant_id.
-- =============================================================

create table if not exists product_variants (
  id               bigint generated always as identity primary key,
  product_id       bigint not null references products(id) on delete cascade,

  -- selectable options (all nullable; not every product needs all dimensions)
  material_color   text,
  size             text,
  finish           text,
  stone            text,
  material_type    text,

  -- business fields
  sku              text not null,
  price_cents      integer not null check (price_cents >= 0),
  stock_quantity   integer not null default 0 check (stock_quantity >= 0),

  -- display overrides (falls back to product.main_image_url when null)
  image_url        text,

  -- physical dimensions (optional, for future use)
  weight_grams     numeric,
  width_mm         numeric,
  length_mm        numeric,

  is_active        boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- SKU must be globally unique
create unique index if not exists product_variants_sku_key
  on product_variants (sku);

-- =============================================================
-- STEP 2: updated_at trigger
-- =============================================================
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists product_variants_set_updated_at on product_variants;
create trigger product_variants_set_updated_at
  before update on product_variants
  for each row execute function set_updated_at();

-- =============================================================
-- STEP 3: Row-Level Security
-- =============================================================
alter table product_variants enable row level security;

-- Anyone can read active variants
create policy product_variants_select_active
  on product_variants for select
  using (is_active = true);

-- No direct client writes — all mutations go through the
-- place_order_atomic SECURITY DEFINER function or admin tools
-- (add an admin policy here when you build the admin panel)

-- =============================================================
-- STEP 4: Seed variants from the existing product
--
-- This reads whatever is currently in your single product row
-- and creates one default variant per product.
-- After running this, go to the Supabase dashboard and add
-- additional variants (Gold/54, Silver/52, etc.) manually or
-- via a seed script.
-- =============================================================
insert into product_variants (
  product_id,
  material_color,
  size,
  sku,
  price_cents,
  stock_quantity,
  image_url,
  is_active
)
select
  id                               as product_id,
  material                         as material_color,  -- existing column
  null                             as size,
  'SKU-' || id::text               as sku,             -- placeholder; update manually
  coalesce(price_cents, 0)         as price_cents,
  coalesce(stock_quantity, 0)      as stock_quantity,
  (images->>0)                      as image_url,
  is_active
from products
on conflict do nothing;

-- =============================================================
-- STEP 5: cart_items table — add variant_id column
-- =============================================================
-- We add variant_id alongside the existing product_id so that
-- old guest carts (stored in localStorage) don't break immediately.
-- Once the frontend is fully migrated we can drop product_id.

alter table cart_items
  add column if not exists variant_id bigint references product_variants(id) on delete cascade;

-- Partial unique index: enforces one row per (user, variant).
-- Only applies to rows where variant_id is set (not null), so old
-- product_id-keyed rows are unaffected during the transition.
create unique index if not exists cart_items_user_id_variant_id_key
  on cart_items (user_id, variant_id)
  where variant_id is not null;

-- After frontend migration is complete, drop the old constraint with:
--   alter table cart_items drop constraint cart_items_user_id_product_id_key;
