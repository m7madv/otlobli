-- Adopt the 2026 Syrian new-lira unit everywhere: 100 old SYP = 1 new SYP.
-- This is deliberately idempotent because production may already be converted.
do $$
declare
  already_new text;
  moved_orders integer;
  moved_items integer;
  moved_wallet integer;
begin
  select value into already_new
  from public.app_settings
  where key = 'syp_denomination';

  if already_new = 'new' then
    raise notice 'New Syrian lira is already active; nothing to migrate';
    return;
  end if;

  -- Pending SYP intents still carry the old unit and must be recreated.
  update public.orders
  set payment_status = 'فشل المطابقة'
  where payment_status = 'بانتظار الدفع'
    and payment_currency = 'SYP';

  update public.wallet_topups
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and payment_currency = 'SYP';

  update public.order_issue_payments
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and payment_currency = 'SYP';

  update public.orders
  set total_syp = round(coalesce(total_syp, 0) / 100.0)::integer,
      wallet_reserved_syp = round(coalesce(wallet_reserved_syp, 0) / 100.0)::integer,
      payment_amount = case
        when payment_currency = 'SYP' and payment_amount is not null
          then round(payment_amount / 100.0, 2)
        else payment_amount
      end;
  get diagnostics moved_orders = row_count;

  update public.order_items
  set price_syp = round(coalesce(price_syp, 0) / 100.0)::integer;
  get diagnostics moved_items = row_count;

  update public.cart_group_items
  set price_syp = round(coalesce(price_syp, 0) / 100.0)::integer;

  update public.wallet_transactions
  set amount_syp = round(coalesce(amount_syp, 0) / 100.0)::integer;
  get diagnostics moved_wallet = row_count;

  update public.wallet_topups
  set requested_amount_syp = round(coalesce(requested_amount_syp, 0) / 100.0)::integer,
      payment_amount = case
        when payment_currency = 'SYP' then round(payment_amount / 100.0, 2)
        else payment_amount
      end;

  update public.order_issue_payments
  set payment_amount = case
    when payment_currency = 'SYP' then round(payment_amount / 100.0, 2)
    else payment_amount
  end;

  update public.coupons
  set min_subtotal_syp = round(coalesce(min_subtotal_syp, 0) / 100.0)::integer;

  update public.coupon_redemptions
  set discount_syp = round(coalesce(discount_syp, 0) / 100.0)::integer;

  update public.payment_verifications
  set amount_syp = round(coalesce(amount_syp, 0) / 100.0)::integer;

  update public.app_settings
  set value = greatest(round(value::numeric / 100.0), 0)::bigint::text
  where key like '%\_syp'
    and value ~ '^\d+(\.\d+)?$';

  insert into public.app_settings (key, value)
  values ('usd_to_syp_rate', '131.70')
  on conflict (key) do update set value = excluded.value;

  insert into public.app_settings (key, value)
  values ('syp_denomination', 'new')
  on conflict (key) do update set value = excluded.value;

  raise notice 'Converted SYP rows: orders %, items %, wallet %',
    moved_orders, moved_items, moved_wallet;
end;
$$;

-- Reject an old-unit writer after conversion. This protects the entire order
-- and ShamCash path from silently returning to 100x totals.
create or replace function public.guard_usd_rate_setting()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  denomination text;
begin
  if tg_op = 'DELETE' then
    if old.key = 'usd_to_syp_rate' then
      raise exception 'usd_to_syp_rate must never be deleted';
    end if;
    return old;
  end if;

  if new.key <> 'usd_to_syp_rate' then return new; end if;

  if new.value !~ '^\d+(\.\d+)?$' or new.value::numeric <= 0 then
    raise exception 'usd_to_syp_rate must be a positive number, got %', new.value;
  end if;

  select value into denomination
  from public.app_settings
  where key = 'syp_denomination';

  if coalesce(denomination, '') = 'new' and new.value::numeric >= 1000 then
    raise exception
      'usd_to_syp_rate % looks like old SYP; update the rate writer to the new-lira unit',
      new.value;
  end if;

  return new;
end;
$$;

drop trigger if exists app_settings_guard_usd_rate on public.app_settings;
create trigger app_settings_guard_usd_rate
before insert or update or delete on public.app_settings
for each row execute function public.guard_usd_rate_setting();
