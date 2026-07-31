-- Least-privilege hardening for the `public` schema.
--
-- Prompted by a Supabase privilege audit that found `anon` and
-- `authenticated` held far broader grants (schema CREATE, full table
-- CRUD including TRUNCATE/REFERENCES/TRIGGER/MAINTAIN, unrestricted
-- sequence access, and PUBLIC-default EXECUTE on every function) than the
-- application actually uses.
--
-- This patch only changes GRANT/REVOKE privileges. It does NOT touch RLS
-- policies, order statuses, storage policies, or any other application
-- behavior — row-level security (see admin_rls_policies.sql,
-- lock_profiles_role_and_orders_rls.sql, create_product_variants.sql,
-- add_variant_images.sql) remains the primary access-control layer;
-- these GRANTs are the outer, coarser boundary in front of it.
--
-- Privilege map verified directly against frontend usage
-- (shop_frontend/src/stores/*.js, views/*.vue) as of 2026-07-31:
--
--   anon (signed-out visitors):
--     • SELECT only on products, product_variants, variant_images
--       (public catalog browsing — src/stores/products.js).
--     • No access to profiles, cart_items, wishlist_items, orders
--       (guest cart/wishlist are localStorage-only, never hit these
--       tables until the user signs in).
--     • No EXECUTE on any authenticated-only RPC.
--
--   authenticated (signed-in customers + admins, RLS-scoped per row):
--     • profiles: SELECT, INSERT, UPDATE
--       (src/stores/auth.js ensureProfile/upsertProfile/fetchProfile;
--       admin read of full_name in src/stores/admin.js fetchOrders).
--       No DELETE — never called anywhere.
--     • cart_items: SELECT, INSERT, UPDATE, DELETE
--       (src/stores/cart.js — full CRUD on the caller's own cart, RLS-scoped).
--     • wishlist_items: SELECT, INSERT, UPDATE, DELETE
--       (src/stores/wishlist.js — full CRUD on the caller's own wishlist,
--       RLS-scoped; UPDATE is exercised via .upsert()).
--     • orders: SELECT only
--       (src/stores/orders.js, src/stores/admin.js fetchOrders,
--       src/views/OrderConfirmView.vue). Order creation goes exclusively
--       through the SECURITY DEFINER place_order_atomic() RPC — the RPC
--       owner's privileges are used for the actual INSERT, so callers
--       never need direct INSERT/UPDATE/DELETE on orders.
--     • products, product_variants: SELECT, INSERT, UPDATE
--       (src/stores/admin.js createProduct/updateProduct/createVariant/
--       updateVariant, RLS-gated by public.is_admin()).
--       NOTE: admin.js also defines deleteProduct()/deleteVariant(), but
--       neither is called from any admin view/component (verified via
--       repo-wide search of src/views/admin/** and src/components/admin/**)
--       and admin_rls_policies.sql intentionally defines no admin DELETE
--       policy for products/product_variants (soft-delete via is_active
--       instead). No DELETE grant is added here, matching both the
--       current RLS enforcement and the requested privilege model. If
--       hard-delete becomes a real product requirement, it needs an
--       explicit RLS policy decision first, not just a GRANT.
--     • variant_images: SELECT, INSERT, UPDATE, DELETE
--       (src/stores/admin.js addVariantImage/updateVariantImage/
--       deleteVariantImage, called from VariantImagesPanel.vue — full
--       CRUD is genuinely used and safe per admin_rls_policies.sql).
--     • EXECUTE on public.place_order_atomic(jsonb, jsonb, uuid, text),
--       public.admin_update_order_status(uuid, text), and
--       public.is_admin() — the only RPCs called from the frontend
--       (src/stores/orders.js, src/stores/admin.js). is_admin() is also
--       invoked internally by RLS policies, which still requires the
--       calling role to hold EXECUTE on it.
--     • No EXECUTE on set_updated_at() — trigger-only, never called
--       directly by the application or any RPC.
--
-- Confirmed via the exported live schema and privilege audit:
--   • All relevant public tables, functions, and sequences are owned by
--     the `postgres` role.
--   • The only public sequences are products_id_seq, product_variants_id_seq,
--     and variant_images_id_seq, and all three back `generated always as
--     identity` columns (products.id, product_variants.id,
--     variant_images.id). Identity-backed sequences never need a direct
--     Data API grant — table INSERT privilege alone is sufficient for the
--     owning role to generate values — so no sequence GRANT is added back
--     for anon or authenticated below.

begin;

-- ── Schema-level ─────────────────────────────────────────────────────────
-- Browser roles must never be able to create new objects in `public`.
revoke create on schema public from public, anon, authenticated;

-- Keep USAGE (required just to see/reference objects in the schema at all).
grant usage on schema public to anon, authenticated;

-- ── Tables: start from a clean slate ────────────────────────────────────
-- Revoking ALL clears SELECT/INSERT/UPDATE/DELETE and also TRUNCATE,
-- REFERENCES, TRIGGER, and MAINTAIN, none of which any browser role needs.
revoke all on table
  public.products,
  public.product_variants,
  public.variant_images,
  public.profiles,
  public.cart_items,
  public.wishlist_items,
  public.orders
from public, anon, authenticated;

-- ── anon: public catalog browsing only ──────────────────────────────────
grant select on table
  public.products,
  public.product_variants,
  public.variant_images
to anon;

-- ── authenticated: explicit allowlist per table ─────────────────────────
-- profiles — no DELETE; role writes are further constrained by RLS
-- (see sql/lock_profiles_role_and_orders_rls.sql).
grant select, insert, update on table public.profiles to authenticated;

-- cart_items / wishlist_items — full CRUD on the caller's own rows,
-- enforced by existing RLS, both genuinely used by the frontend.
grant select, insert, update, delete on table public.cart_items to authenticated;
grant select, insert, update, delete on table public.wishlist_items to authenticated;

-- orders — read-only for customers and admins; all writes happen inside
-- SECURITY DEFINER RPCs (place_order_atomic, admin_update_order_status),
-- which run with the function owner's privileges, not the caller's.
grant select on table public.orders to authenticated;

-- products / product_variants — admin catalog management, RLS-gated by
-- public.is_admin(). No DELETE (see note above).
grant select, insert, update on table public.products to authenticated;
grant select, insert, update on table public.product_variants to authenticated;

-- variant_images — admin image management, full CRUD is genuinely used.
grant select, insert, update, delete on table public.variant_images to authenticated;

-- ── Sequences ────────────────────────────────────────────────────────────
-- Clear any excessive sequence privileges first.
revoke all on all sequences in schema public from public, anon, authenticated;

-- No sequence privileges are granted back to any Data API role: all three
-- audited sequences (products_id_seq, product_variants_id_seq,
-- variant_images_id_seq) back `generated always as identity` columns, so
-- table-level INSERT privilege is sufficient and direct sequence access
-- is unnecessary.

-- ── Functions ────────────────────────────────────────────────────────────
-- PostgreSQL grants EXECUTE on new functions to PUBLIC by default; clear
-- that out schema-wide, then grant back only what the app actually calls.
revoke execute on all functions in schema public from public, anon, authenticated;

grant execute on function public.is_admin() to authenticated;
grant execute on function public.place_order_atomic(jsonb, jsonb, uuid, text) to authenticated;
grant execute on function public.admin_update_order_status(uuid, text) to authenticated;

-- set_updated_at() intentionally receives no EXECUTE grant to any role —
-- it is only ever invoked as a BEFORE UPDATE trigger (see
-- create_product_variants.sql), which runs under the table owner's
-- privileges regardless of caller grants.

-- ── Default privileges for future objects (postgres-owned only) ────────
-- These ALTER DEFAULT PRIVILEGES statements only change what happens to
-- objects `postgres` creates AFTER this point — they do not revoke any
-- existing privilege on any existing object, and they do not touch
-- service_role's standing privileges on objects that already exist.

-- Future functions created by postgres must not inherit PostgreSQL's
-- global PUBLIC execute default.
alter default privileges for role postgres
revoke execute on functions from public;

-- Future objects in public remain inaccessible through Data API roles
-- until explicitly granted.
alter default privileges for role postgres
in schema public
revoke all privileges on tables
from public, anon, authenticated, service_role;

alter default privileges for role postgres
in schema public
revoke all privileges on sequences
from public, anon, authenticated, service_role;

alter default privileges for role postgres
in schema public
revoke execute on functions
from anon, authenticated, service_role;

commit;
