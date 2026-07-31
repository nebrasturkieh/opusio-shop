-- Lock down profiles.role from client-side writes; restrict orders writes
-- to server-side RPCs only.
--
-- This migration was applied directly to the live Supabase project via the
-- SQL editor on 2026-07-31 and is recorded here for version control after
-- the fact. Do NOT re-run it against a database where it has already been
-- applied without reviewing for idempotency (the DROP POLICY IF EXISTS
-- guards make it safe to re-run, but the column default change is a no-op
-- if already set).
--
-- What this does:
--   1. profiles.role now defaults to 'user' at the database level, so
--      client code can omit the column entirely on insert.
--   2. profiles_insert_own requires role = 'user' on insert, and
--      profiles_update_own requires the row to keep its existing
--      user/admin standing (role = 'admin' only if public.is_admin() is
--      already true for the caller, otherwise role = 'user'). Combined
--      with the app no longer sending a role field at all, this makes
--      client-side privilege escalation via profiles impossible while
--      still letting an existing administrator edit their own profile.
--      Role promotion to 'admin' must be done directly in the database
--      (e.g. Supabase SQL editor) by an operator, outside of any
--      RLS-governed client path.
--   3. orders can no longer be inserted/updated/deleted directly by
--      customers (replaces the old users_manage_own_orders policy).
--      Order creation still goes through the SECURITY DEFINER
--      place_order_atomic() RPC (sql/place_order_atomic_v3.sql) and status
--      changes through admin_update_order_status() RPC
--      (sql/admin_update_order_status.sql) — neither is affected by this
--      migration. Customers retain read-only access to their own orders
--      via the new users_read_own_orders policy.

begin;

alter table public.profiles
  alter column role set default 'user';

drop policy if exists "profiles_insert_own" on public.profiles;

create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (
  (select auth.uid()) = id
  and role = 'user'
);

drop policy if exists "profiles_update_own" on public.profiles;

create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (
  (select auth.uid()) = id
)
with check (
  (select auth.uid()) = id
  and role = case
    when (select public.is_admin()) then 'admin'
    else 'user'
  end
);

drop policy if exists "users_manage_own_orders" on public.orders;

create policy "users_read_own_orders"
on public.orders
for select
to authenticated
using (
  (select auth.uid()) = user_id
);

commit;
