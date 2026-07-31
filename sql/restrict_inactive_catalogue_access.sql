-- Restrict inactive catalogue rows (products, product_variants,
-- variant_images) from guest/customer visibility while preserving full
-- administrator access.
--
-- ── Evidence gathered from this repository ──────────────────────────────
--
-- product_variants.is_active (create_product_variants.sql) already has an
-- RLS policy restricting non-admin SELECT to active rows:
--     create policy product_variants_select_active
--       on product_variants for select using (is_active = true);
-- combined with the separately-added admin policy
-- (product_variants_admin_select, admin_rls_policies.sql) that grants
-- authenticated admins full SELECT via public.is_admin(). Both are
-- confirmed by exact name and effect from tracked SQL.
--
-- GAP 1 (fixed below): product_variants_select_active only checks the
-- variant's OWN is_active flag. It does not check whether the PARENT
-- product (products.is_active, referenced in place_order_atomic_v3.sql as
-- p.is_active) is also active. A variant marked active on a product that
-- has been deactivated would still be independently visible to guests —
-- this violates "variants belonging to an inactive product must not
-- remain independently visible."
--
-- GAP 2 (fixed below): variant_images has no is_active column of its own
-- (add_variant_images.sql) and its only SELECT policy is fully open:
--     create policy variant_images_select_public
--       on variant_images for select using (true);
-- confirmed by exact name and effect. This exposes every image for every
-- variant/product regardless of active state, to anyone, via direct table
-- query.
--
-- GAP 3 (products table — confirmed via live Supabase audit): RLS is
-- enabled on public.products, and the existing permissive public SELECT
-- policy is confirmed as:
--     create policy products_public_read
--       on products for select to public using (true);
-- (name, role, and qualification confirmed live). This policy is fully
-- open and exposes every inactive product to anyone. It is replaced below
-- by its exact confirmed name — leaving it in place would bypass any
-- additional permissive "active only" policy, since permissive policies
-- combine with OR and the broadest one wins.
--
-- This patch only adds/corrects SELECT-time RLS policies. It does not
-- change grants (see sql/harden_public_privileges.sql, unchanged), order
-- status handling (see sql/align_order_status_constraint.sql, unchanged),
-- checkout, place_order_atomic, storage policies, or any admin mutation
-- policy.

begin;

-- ── product_variants: also require the parent product to be active ─────
drop policy if exists "product_variants_select_active" on public.product_variants;

create policy "product_variants_select_active"
on public.product_variants
for select
using (
  is_active = true
  and exists (
    select 1
    from public.products p
    where p.id = product_variants.product_id
      and p.is_active = true
  )
);

-- ── variant_images: derive visibility from the parent variant + product ─
drop policy if exists "variant_images_select_public" on public.variant_images;

create policy "variant_images_select_public"
on public.variant_images
for select
using (
  exists (
    select 1
    from public.product_variants pv
    join public.products p on p.id = pv.product_id
    where pv.id = variant_images.variant_id
      and pv.is_active = true
      and p.is_active = true
  )
);

-- ── products: replace the confirmed broad public policy (see GAP 3) ─────
-- Enabling RLS is idempotent/safe even though it is already enabled live;
-- kept here for completeness and re-runnability.
alter table public.products enable row level security;

drop policy if exists "products_public_read" on public.products;

create policy "products_public_read"
on public.products
for select
using (is_active = true);

-- Existing admin policies (products_admin_select, product_variants_admin_select,
-- variant_images_admin_all — all gated by public.is_admin(), see
-- admin_rls_policies.sql) are untouched and continue to grant
-- administrators full SELECT (including inactive rows) via normal
-- permissive-policy OR-composition with the policies above.

commit;
