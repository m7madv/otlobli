-- Emergency financial invariant: a collision must never lower the amount due.
-- The existing allocation loops may probe lower values for historical reasons;
-- this trigger rejects every non-nominal probe, making the effective policy
-- exact-only until a separately tested lease/overage-credit design is deployed.

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

  if required_amount <= 0 or new.payment_amount <> required_amount then
    raise exception using
      errcode = 'P0001',
      message = 'payment amount collision; retry after the existing intent expires';
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_exact_payment_intent()
  from public, anon, authenticated;
grant execute on function public.enforce_exact_payment_intent()
  to service_role;

drop trigger if exists orders_exact_payment_amount on public.orders;
create trigger orders_exact_payment_amount
before insert on public.orders
for each row execute function public.enforce_exact_payment_intent();

drop trigger if exists wallet_topups_exact_payment_amount on public.wallet_topups;
create trigger wallet_topups_exact_payment_amount
before insert on public.wallet_topups
for each row execute function public.enforce_exact_payment_intent();

drop trigger if exists order_issue_exact_payment_amount on public.order_issue_payments;
create trigger order_issue_exact_payment_amount
before insert on public.order_issue_payments
for each row execute function public.enforce_exact_payment_intent();

-- A customer cannot reserve a ladder of colliding top-up values for themselves.
update public.wallet_topups
set status = 'منتهي'
where status = 'بانتظار الدفع' and expires_at <= now();

with ranked as (
  select id,
         row_number() over (
           partition by customer_id
           order by created_at desc, id desc
         ) as position
  from public.wallet_topups
  where status = 'بانتظار الدفع'
)
update public.wallet_topups as topup
set status = 'منتهي'
from ranked
where topup.id = ranked.id and ranked.position > 1;

create unique index if not exists wallet_topups_one_pending_per_customer_uidx
  on public.wallet_topups (customer_id)
  where status = 'بانتظار الدفع';

notify pgrst, 'reload schema';
