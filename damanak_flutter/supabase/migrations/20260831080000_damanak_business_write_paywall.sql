-- Correct the first business-write guard deployed in 0700: keep deletion and
-- contractual refunds/closing an open register available after expiry, while
-- every new POS, catalog, inventory, supplier, and purchasing write requires
-- a usable subscription at the database boundary.

create or replace function public.enforce_usable_subscription_for_core_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_store_id uuid;
begin
  if coalesce((select auth.role()), '') <> 'authenticated' then
    return new;
  end if;

  if current_setting('damanak.write_context', true) = 'return_sale' then
    return new;
  end if;

  if tg_table_name = 'register_sessions' and tg_op = 'UPDATE'
     and to_jsonb(old)->>'status' = 'open'
     and to_jsonb(new)->>'status' = 'closed'
     and to_jsonb(new)->>'id' = to_jsonb(old)->>'id'
     and to_jsonb(new)->>'store_id' = to_jsonb(old)->>'store_id'
     and to_jsonb(new)->>'branch_id' = to_jsonb(old)->>'branch_id'
     and to_jsonb(new)->>'opened_by' = to_jsonb(old)->>'opened_by'
     and to_jsonb(new)->>'opened_at' = to_jsonb(old)->>'opened_at' then
    return new;
  end if;

  target_store_id := nullif(to_jsonb(new)->>'store_id', '')::uuid;
  if target_store_id is null then
    raise exception 'STORE_REQUIRED';
  end if;
  if not public.subscription_is_usable(target_store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;
  return new;
end;
$$;

do $business_write_triggers$
declare
  table_name text;
begin
  foreach table_name in array array[
    'products',
    'branches',
    'customers',
    'inventory_levels',
    'stock_movements',
    'sales',
    'sale_lines',
    'sale_payments',
    'sale_returns',
    'register_sessions',
    'suppliers',
    'purchase_orders',
    'purchase_order_lines',
    'warranties'
  ] loop
    execute format(
      'drop trigger if exists %I on public.%I',
      table_name || '_usable_subscription_guard',
      table_name
    );
    execute format(
      'drop trigger if exists %I on public.%I',
      table_name || '_00_subscription_write_guard',
      table_name
    );
    execute format(
      'create trigger %I before insert or update on public.%I '
      || 'for each row execute function '
      || 'public.enforce_usable_subscription_for_core_write()',
      table_name || '_00_subscription_write_guard',
      table_name
    );
  end loop;
end;
$business_write_triggers$;

revoke all on function public.enforce_usable_subscription_for_core_write()
  from public, anon, authenticated;

create or replace function public.return_sale(
  target_store_id uuid,
  target_sale_id uuid,
  returned_lines jsonb,
  refund_method text,
  return_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  sale_row public.sales%rowtype;
  line_row public.sale_lines%rowtype;
  return_id uuid;
  item jsonb;
  return_quantity numeric;
  refund_value numeric := 0;
  line_refund numeric;
  everything_returned boolean;
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if refund_method not in (
    'cash', 'card', 'bank_transfer', 'digital_wallet', 'other'
  ) then
    raise exception 'INVALID_REFUND_METHOD';
  end if;
  select * into sale_row from public.sales
  where id = target_sale_id and store_id = target_store_id
    and status not in ('returned', 'voided') for update;
  if not found then raise exception 'SALE_NOT_RETURNABLE'; end if;

  -- This setting is transaction-local and is set only after membership and
  -- sale validation. It lets the refund update inventory and sale totals even
  -- if the subscription expired after the original sale.
  perform set_config('damanak.write_context', 'return_sale', true);

  insert into public.sale_returns(
    sale_id, store_id, refund_method, refund_amount, reason, created_by
  ) values (
    target_sale_id, target_store_id, refund_method, 0,
    coalesce(nullif(trim(return_reason), ''), 'مرتجع عميل'), auth.uid()
  ) returning id into return_id;

  for item in select *
    from jsonb_array_elements(coalesce(returned_lines, '[]'::jsonb))
  loop
    return_quantity := (item->>'quantity')::numeric;
    select * into line_row from public.sale_lines
    where id = (item->>'sale_line_id')::uuid and sale_id = target_sale_id
    for update;
    if not found or return_quantity <= 0
       or line_row.returned_quantity + return_quantity > line_row.quantity then
      raise exception 'INVALID_RETURN_QUANTITY';
    end if;
    line_refund := round(
      line_row.line_total / line_row.quantity * return_quantity,
      3
    );
    refund_value := refund_value + line_refund;
    update public.sale_lines
    set returned_quantity = returned_quantity + return_quantity
    where id = line_row.id;
    update public.inventory_levels
    set on_hand = on_hand + return_quantity, updated_at = now()
    where branch_id = sale_row.branch_id and product_id = line_row.product_id;
    insert into public.stock_movements(
      store_id, branch_id, product_id, movement_type, quantity, unit_cost,
      reference_type, reference_id, note, created_by
    ) values (
      target_store_id, sale_row.branch_id, line_row.product_id, 'return_in',
      return_quantity, line_row.unit_cost, 'sale_return', return_id,
      coalesce(return_reason, ''), auth.uid()
    );
    insert into public.sale_return_lines(
      return_id, sale_line_id, quantity, refund_amount
    ) values (return_id, line_row.id, return_quantity, line_refund);

    if line_row.returned_quantity + return_quantity >= line_row.quantity then
      update public.warranties set voided_at = now()
      where sale_line_id = line_row.id and voided_at is null;
    end if;
  end loop;
  if refund_value <= 0 then raise exception 'EMPTY_RETURN'; end if;

  update public.sale_returns
  set refund_amount = refund_value
  where id = return_id;
  select bool_and(returned_quantity >= quantity) into everything_returned
  from public.sale_lines where sale_id = target_sale_id;
  update public.sales
  set refunded_amount = refunded_amount + refund_value,
      status = case
        when everything_returned then 'returned'
        else 'partially_returned'
      end,
      updated_at = now()
  where id = target_sale_id;
end;
$$;

revoke all on function public.return_sale(uuid, uuid, jsonb, text, text)
  from public, anon;
grant execute on function public.return_sale(uuid, uuid, jsonb, text, text)
  to authenticated;

do $verification$
begin
  if exists (
    select 1
    from pg_catalog.pg_proc procedure
    join pg_catalog.pg_namespace namespace
      on namespace.oid = procedure.pronamespace
    where namespace.nspname = 'public'
      and pg_catalog.has_function_privilege(
        'anon', procedure.oid, 'EXECUTE'
      )
  ) then
    raise exception 'DAMANAK_ANON_FUNCTION_EXECUTE_REMAINS';
  end if;
end;
$verification$;
