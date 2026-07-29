-- Keep production aligned with the app's canonical Arabic payment statuses.
-- Some older builds/types allowed mojibake legacy strings, which can make
-- wallet-only checkout fail against orders_payment_status_check.

alter table public.orders
  drop constraint if exists orders_payment_status_check;

update public.orders
set payment_status = case
  when payment_status in ('مدفوع', 'ظ…ط¯ظپظˆط¹', 'paid', 'paid_pending') then 'مدفوع'
  when payment_status in ('فشل المطابقة', 'ظپط´ظ„ ط§ظ„ظ…ط·ط§ط¨ظ‚ط©', 'failed', 'failed_match', 'payment_failed') then 'فشل المطابقة'
  else 'بانتظار الدفع'
end
where payment_status is null
   or payment_status not in ('بانتظار الدفع', 'مدفوع', 'فشل المطابقة');

alter table public.orders
  add constraint orders_payment_status_check
  check (payment_status in ('بانتظار الدفع', 'مدفوع', 'فشل المطابقة'));
