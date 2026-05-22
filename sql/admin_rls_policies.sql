-- Admin RLS policies for the admin panel.
--
-- Strategy:
--   1. A stable SECURITY DEFINER helper function `public.is_admin()` avoids
--      repeating a subquery in every policy and prevents privilege escalation.
--      Always reference it as public.is_admin() inside policies to avoid
--      search_path confusion.
--   2. products / product_variants: SELECT, INSERT, UPDATE only — no DELETE.
--      Old orders snapshot data historically references these rows; deleting
--      catalog entries could create orphaned references. Use is_active = false
--      (soft delete) instead.
--   3. variant_images: full CRUD — image assets are safely removable.
--   4. orders: SELECT all only. Status changes go through admin_update_order_status().
--      INSERT goes through place_order_atomic. DELETE excluded — immutable records.
--   5. profiles: SELECT only — admins read customer info; role changes should
--      go through a dedicated RPC, not direct writes.
--   6. DROP POLICY IF EXISTS before each CREATE POLICY so this script is
--      safely re-runnable without errors.

-- ── Helper function ────────────────────────────────────────────────────────
-- Reads profiles.role for the current authenticated user.
-- SECURITY DEFINER so RLS on profiles does not block the lookup.
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
      and role = 'admin'
  )
$$;

-- ── products ───────────────────────────────────────────────────────────────
-- No DELETE: deactivate with is_active = false instead of hard-deleting.
drop policy if exists products_admin_select on products;
drop policy if exists products_admin_insert on products;
drop policy if exists products_admin_update on products;

create policy products_admin_select on products
  for select
  to authenticated
  using (public.is_admin());

create policy products_admin_insert on products
  for insert
  to authenticated
  with check (public.is_admin());

create policy products_admin_update on products
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ── product_variants ───────────────────────────────────────────────────────
-- Existing policy: product_variants_select_active (public read, active only).
-- Admin policy lets admin see and manage ALL variants including inactive ones.
-- No DELETE: deactivate with is_active = false.
drop policy if exists product_variants_admin_select on product_variants;
drop policy if exists product_variants_admin_insert on product_variants;
drop policy if exists product_variants_admin_update on product_variants;

create policy product_variants_admin_select on product_variants
  for select
  to authenticated
  using (public.is_admin());

create policy product_variants_admin_insert on product_variants
  for insert
  to authenticated
  with check (public.is_admin());

create policy product_variants_admin_update on product_variants
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ── variant_images ─────────────────────────────────────────────────────────
-- Existing policy: variant_images_select_public (public read).
-- Image assets are safely removable, so full CRUD is allowed here.
drop policy if exists variant_images_admin_all on variant_images;

create policy variant_images_admin_all on variant_images
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ── orders ─────────────────────────────────────────────────────────────────
-- Admin can SELECT all orders but cannot UPDATE directly.
-- Status changes go through admin_update_order_status(p_order_id, p_status),
-- a SECURITY DEFINER RPC that validates the status value and writes only
-- the status and updated_at columns. See sql/admin_update_order_status.sql.
drop policy if exists orders_admin_select on orders;
drop policy if exists orders_admin_update on orders;  -- intentionally not recreated

create policy orders_admin_select on orders
  for select
  to authenticated
  using (public.is_admin());

-- ── profiles ───────────────────────────────────────────────────────────────
-- Admin reads all profiles to show customer names on orders.
-- No INSERT/UPDATE/DELETE — role promotion should go through a dedicated RPC.
drop policy if exists profiles_admin_select on profiles;

create policy profiles_admin_select on profiles
  for select
  to authenticated
  using (public.is_admin());
