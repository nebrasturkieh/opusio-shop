-- =============================================================
-- add_variant_images.sql
--
-- Run AFTER create_product_variants.sql.
--
-- Adds a normalised gallery table for per-variant images.
--
-- Responsibilities split:
--   product_variants.image_url  → cover/thumbnail used in cards,
--                                  cart, checkout, order snapshot
--   variant_images              → full gallery in ProductView;
--                                  switches when variant changes;
--                                  supports ordering and future
--                                  admin image management
-- =============================================================

-- =============================================================
-- STEP 1: Create variant_images table
-- =============================================================
create table if not exists variant_images (
  id          bigint generated always as identity primary key,
  variant_id  bigint not null references product_variants(id) on delete cascade,

  image_url   text not null,

  alt_text    text,

  -- Optional role label.
  -- Suggested values: 'front' | 'side' | 'on_hand' | 'box'
  -- NULL is valid for unclassified images.
  role        text,

  -- Lower = displayed first. sort_order = 0 is the lead gallery image.
  sort_order  integer not null default 0,

  created_at  timestamptz not null default now()
);

-- Fast ordered lookup by variant
create index if not exists variant_images_variant_id_sort_idx
  on variant_images (variant_id, sort_order);

-- =============================================================
-- STEP 2: Row-Level Security
-- =============================================================
alter table variant_images enable row level security;

-- Publicly readable — variant active-state is already enforced
-- on product_variants; no need to repeat it here.
create policy variant_images_select_public
  on variant_images for select
  using (true);

-- No direct client writes — managed via admin tooling or SQL.
-- (Add an admin policy here when the admin panel is built.)
