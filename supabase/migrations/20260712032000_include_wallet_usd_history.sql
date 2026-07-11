-- Preserve the USD amount recorded at transaction time. Recomputing old
-- movements with today's exchange rate changes the historical ledger.

create or replace function public.get_customer_account(p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  cleaned_phone text := regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g');
  found_customer public.customers%rowtype;
  latest_order public.orders%rowtype;
  created_customer_id uuid;
  wallet_balance integer := 0;
  order_list jsonb := '[]'::jsonb;
  tx_list jsonb := '[]'::jsonb;
begin
  if cleaned_phone = '' then
    return jsonb_build_object(
      'profile', null,
      'orders', '[]'::jsonb,
      'walletBalanceSyp', 0,
      'walletTransactions', '[]'::jsonb
    );
  end if;

  select * into found_customer
  from public.customers
  where phone = cleaned_phone
  limit 1;

  if not found then
    select * into latest_order
    from public.orders
    where phone = cleaned_phone
    order by created_at desc
    limit 1;

    if found then
      created_customer_id := public.ensure_customer(
        cleaned_phone,
        latest_order.customer_name,
        coalesce(nullif(latest_order.city, ''), 'دمشق'),
        '',
        coalesce(latest_order.city, ''),
        coalesce(latest_order.address, '')
      );

      update public.orders
      set customer_id = created_customer_id
      where phone = cleaned_phone and customer_id is null;

      return public.get_customer_account(cleaned_phone);
    end if;

    select public.customer_orders_json(null, cleaned_phone) into order_list;
    return jsonb_build_object(
      'profile', null,
      'orders', order_list,
      'walletBalanceSyp', 0,
      'walletTransactions', '[]'::jsonb
    );
  end if;

  select public.customer_orders_json(found_customer.id, cleaned_phone) into order_list;
  select coalesce(sum(amount_syp), 0)::integer into wallet_balance
  from public.wallet_transactions
  where customer_id = found_customer.id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', wt.id,
    'amountSyp', wt.amount_syp,
    'amountUsd', wt.amount_usd,
    'kind', wt.kind,
    'note', wt.note,
    'orderId', wt.order_id,
    'createdAt', wt.created_at
  ) order by wt.created_at desc), '[]'::jsonb) into tx_list
  from public.wallet_transactions wt
  where wt.customer_id = found_customer.id
  limit 30;

  return jsonb_build_object(
    'profile', jsonb_build_object(
      'name', coalesce(found_customer.name, ''),
      'phone', found_customer.phone,
      'governorate', coalesce(found_customer.governorate, 'دمشق'),
      'city', coalesce(found_customer.city, ''),
      'qadmousBranch', coalesce(found_customer.qadmous_branch, ''),
      'pickupLabel', coalesce(found_customer.pickup_label, ''),
      'details', coalesce(found_customer.details, ''),
      'notificationPrefs', coalesce(found_customer.notification_prefs, '{}'::jsonb),
      'walletBalanceSyp', wallet_balance
    ),
    'orders', order_list,
    'walletBalanceSyp', wallet_balance,
    'walletTransactions', tx_list
  );
end;
$$;

revoke all on function public.get_customer_account(text) from public;
grant execute on function public.get_customer_account(text) to anon, authenticated;
