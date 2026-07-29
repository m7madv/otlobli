-- Normalize order payment status before the table check constraint and before
-- exact-payment triggers run. This keeps old/mobile builds from failing
-- orders_payment_status_check while preserving canonical Arabic values.

create or replace function public.normalize_order_payment_status_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  s text := coalesce(nullif(trim(new.payment_status), ''), 'بانتظار الدفع');
begin
  if s in ('مدفوع', 'ظ…ط¯ظپظˆط¹', 'paid', 'paid_pending') then
    new.payment_status := 'مدفوع';
  elsif s in ('فشل المطابقة', 'ظپط´ظ„ ط§ظ„ظ…ط·ط§ط¨ظ‚ط©', 'failed', 'failed_match', 'payment_failed') then
    new.payment_status := 'فشل المطابقة';
  else
    new.payment_status := 'بانتظار الدفع';
  end if;
  return new;
end;
$$;

revoke all on function public.normalize_order_payment_status_before_write() from public, anon, authenticated;
grant execute on function public.normalize_order_payment_status_before_write() to service_role;

drop trigger if exists orders_aa_normalize_payment_status on public.orders;
create trigger orders_aa_normalize_payment_status
before insert or update of payment_status on public.orders
for each row execute function public.normalize_order_payment_status_before_write();

update public.orders
set payment_status = case
  when payment_status in ('مدفوع', 'ظ…ط¯ظپظˆط¹', 'paid', 'paid_pending') then 'مدفوع'
  when payment_status in ('فشل المطابقة', 'ظپط´ظ„ ط§ظ„ظ…ط·ط§ط¨ظ‚ط©', 'failed', 'failed_match', 'payment_failed') then 'فشل المطابقة'
  else 'بانتظار الدفع'
end
where payment_status is null
   or payment_status not in ('بانتظار الدفع', 'مدفوع', 'فشل المطابقة');

alter table public.orders
  drop constraint if exists orders_payment_status_check;

alter table public.orders
  add constraint orders_payment_status_check
  check (payment_status in ('بانتظار الدفع', 'مدفوع', 'فشل المطابقة'));
