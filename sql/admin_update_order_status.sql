-- RPC: admin_update_order_status
--
-- Why an RPC instead of a direct UPDATE via RLS?
-- RLS UPDATE policies cannot restrict which columns the caller modifies.
-- By removing the orders_admin_update RLS policy and routing all admin
-- status changes through this function, we guarantee that:
--   • only the `status` column is ever modified
--   • only authenticated admins can call it
--   • the status value is validated against the allowed set
--   • updated_at is kept in sync automatically

drop function if exists public.admin_update_order_status(uuid, text);

create or replace function public.admin_update_order_status(
  p_order_id  uuid,
  p_status    text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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
$$;

-- Only authenticated users can call this function.
-- The is_admin() check inside the body gates actual access.
revoke all on function public.admin_update_order_status(uuid, text) from public;
grant execute on function public.admin_update_order_status(uuid, text) to authenticated;
