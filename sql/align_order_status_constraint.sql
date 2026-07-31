-- Align `public.orders.orders_status_check` with the statuses already
-- validated by public.admin_update_order_status(uuid, text) (see
-- sql/admin_update_order_status.sql).
--
-- Audited mismatch:
--   • orders_status_check (current, live) only allows:
--       pending, paid, shipped, cancelled
--   • admin_update_order_status(uuid, text) already validates against the
--     full canonical set:
--       pending, paid, processing, shipped, delivered, cancelled, refunded
--
-- Because the RPC's allowlist is a superset of the table constraint, an
-- admin selecting "processing", "delivered", or "refunded" in the admin
-- UI (src/stores/admin.js ORDER_STATUSES, src/views/admin/AdminOrdersView.vue)
-- passes the RPC's own validation but is then rejected by the database
-- constraint, causing a runtime failure. This patch brings the table
-- constraint into agreement with the already-correct RPC allowlist.
--
-- This patch only corrects the CHECK constraint. It does not change the
-- `status` column's default, any other constraint, RLS policies, grants,
-- storage policies, place_order_atomic, or any order-lifecycle/transition
-- behavior.

begin;

alter table public.orders
  drop constraint if exists orders_status_check;

-- Adding the constraint without NOT VALID (the default) forces Postgres to
-- validate every existing row against the new list immediately, inside
-- this transaction. If any existing row holds a status outside this set,
-- the ALTER TABLE fails and the entire transaction rolls back atomically —
-- no partial application.
alter table public.orders
  add constraint orders_status_check
  check (status in (
    'pending',
    'paid',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded'
  ));

commit;
