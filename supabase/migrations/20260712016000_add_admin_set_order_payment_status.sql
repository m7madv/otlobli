-- إصلاح عاجل: زر «تأكيد الدفع» في لوحة الإدارة معطل لأن دالة
-- admin_set_order_payment_status غير موجودة في الإنتاج — النسخة المطبقة من
-- تقوية الدفع (20260711) كانت مسودة أقدم لا تشملها، بينما دالة admin-orders
-- المنشورة تستدعيها. التعريف أدناه منسوخ حرفياً من الصيغة النهائية في ملف
-- 20260711_harden_customer_payments.sql (توابعها apply_order_wallet_reservation
-- وعمود payment_matched_by موجودان في الإنتاج — تحققت بالفحص المباشر).
-- hotfix الجلسة الموازية (20260712020000) يعيد التعريف نفسه لاحقاً — متوافق.
create or replace function public.admin_set_order_payment_status(
  p_order_id text,
  p_payment_status text,
  p_paid_at date default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order public.orders%rowtype;
begin
  if p_payment_status not in ('بانتظار الدفع', 'مدفوع', 'فشل المطابقة') then
    raise exception 'invalid payment status';
  end if;

  select * into target_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'order not found'; end if;
  if target_order.payment_status = 'مدفوع' and p_payment_status <> 'مدفوع' then
    raise exception 'paid order requires an explicit refund workflow';
  end if;

  if p_payment_status = 'مدفوع' and target_order.payment_status <> 'مدفوع' then
    perform public.apply_order_wallet_reservation(target_order.id);
    update public.orders
    set payment_status = 'مدفوع',
        paid_at = coalesce(p_paid_at, current_date),
        status_index = greatest(status_index, 1),
        payment_matched_by = 'admin-manual'
    where id = target_order.id;
    insert into public.order_events (order_id, status_index, title, note)
    values (target_order.id, greatest(target_order.status_index, 1), 'تم تأكيد الدفع يدوياً', 'تأكيد إداري');
  elsif p_payment_status <> target_order.payment_status then
    update public.orders
    set payment_status = p_payment_status,
        paid_at = case when p_payment_status = 'مدفوع' then coalesce(p_paid_at, current_date) else null end
    where id = target_order.id;
  end if;

  return jsonb_build_object('ok', true, 'orderId', target_order.id, 'paymentStatus', p_payment_status);
end;
$$;

revoke all on function public.admin_set_order_payment_status(text, text, date) from public, anon, authenticated;
grant execute on function public.admin_set_order_payment_status(text, text, date) to service_role;
