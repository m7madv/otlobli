-- Payment creation resolves collisions by nudging the requested amount down in
-- tiny steps. Accept the same bounded window here instead of rejecting the
-- collision candidate that the trusted creation functions just produced.
create or replace function public.enforce_exact_payment_intent()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  usd_rate numeric;
  required_amount numeric;
  remaining_syp integer;
  metadata_requested_usd text;
  unit_step numeric;
  max_steps integer := 120;
  min_amount numeric;
begin
  select value::numeric into usd_rate
  from public.app_settings
  where key = 'usd_to_syp_rate';
  usd_rate := case when usd_rate > 0 then usd_rate else 13000 end;

  if tg_table_name = 'orders' then
    if new.payment_status <> 'بانتظار الدفع' or new.payment_amount is null then
      return new;
    end if;

    remaining_syp := greatest(
      coalesce(new.total_syp, 0) - coalesce(new.wallet_reserved_syp, 0),
      0
    );
    required_amount := case
      when new.payment_currency = 'USD' then round(remaining_syp / usd_rate, 2)
      else remaining_syp::numeric
    end;
  elsif tg_table_name = 'wallet_topups' then
    if new.status <> 'بانتظار الدفع' then return new; end if;

    if new.payment_currency = 'USD' then
      metadata_requested_usd := coalesce(new.metadata->>'requestedUsd', '');
      required_amount := case
        when metadata_requested_usd ~ '^\d+(?:\.\d{1,2})?$'
          then round(metadata_requested_usd::numeric, 2)
        else round(coalesce(new.requested_amount_syp, 0) / usd_rate, 2)
      end;
    else
      required_amount := coalesce(new.requested_amount_syp, 0)::numeric;
    end if;
  elsif tg_table_name = 'order_issue_payments' then
    if new.status <> 'بانتظار الدفع' then return new; end if;

    required_amount := case
      when new.payment_currency = 'USD'
        then round(coalesce(new.requested_amount_usd, 0), 2)
      else round(coalesce(new.requested_amount_usd, 0) * usd_rate)
    end;
  else
    raise exception 'unsupported payment intent table';
  end if;

  unit_step := case when new.payment_currency = 'USD' then 0.01 else 1 end;
  min_amount := required_amount - (max_steps * unit_step);

  if required_amount <= 0
     or new.payment_amount > required_amount
     or new.payment_amount < min_amount then
    raise exception using
      errcode = 'P0001',
      message = format(
        'payment amount %s is outside the allowed window [%s, %s]',
        new.payment_amount, greatest(min_amount, 0), required_amount
      );
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_exact_payment_intent() from public, anon, authenticated;
grant execute on function public.enforce_exact_payment_intent() to service_role;
