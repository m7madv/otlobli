-- v60: (1) فاتورة الطلب — بنود رسوم يحررها المشرف (شحن/رسوم منصة...) وتظهر
-- للزبون في تفاصيل الطلب. (2) حل مشاكل الخيارات ذاتياً: المشرف يعرض خيارات
-- (مقاسات/ألوان) في ملاحظة المشكلة، والزبون يختار من التطبيق فيُحدَّث عنصر
-- الطلب مباشرة. (3) إصلاح تراجع أمني: migration 20260712000000 أُلّفت قبل
-- تطبيق 20260711_harden_customer_payments لكنها طُبّقت بعدها، فأعادت منح
-- anon/authenticated على أربع دوال قديمة كانت التقوية قد قصرتها على
-- service_role — نعيد سحبها هنا كما قررتها التقوية.

alter table public.orders
  add column if not exists invoice jsonb not null default '[]'::jsonb;

-- ── (3) إعادة تطبيق قرارات التقوية التي دهستها 20260712000000 ──────────────
revoke all on function public.submit_order(jsonb) from public, anon, authenticated;
grant execute on function public.submit_order(jsonb) to service_role;

revoke all on function public.create_pending_order(jsonb, text) from public, anon, authenticated;
grant execute on function public.create_pending_order(jsonb, text) to service_role;

revoke all on function public.submit_order_custom_fix(text, text, text, text) from public, anon, authenticated;
grant execute on function public.submit_order_custom_fix(text, text, text, text) to service_role;

revoke all on function public.customer_orders_json(uuid, text) from public, anon, authenticated;
grant execute on function public.customer_orders_json(uuid, text) to service_role;

-- ── (2) تحديث خيار عنصر طلب (مقاس/لون) ─────────────────────────────────────
-- النواة (بلا توكن): service_role فقط، على نمط التقوية.
create or replace function public.submit_order_option_fix(
  target_order_id text,
  p_product_id text,
  p_field text,
  p_value text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
  clean_value text := left(trim(coalesce(p_value, '')), 120);
begin
  if coalesce(target_order_id, '') = '' or coalesce(p_product_id, '') = '' or clean_value = '' then
    return false;
  end if;
  if p_field not in ('size', 'color') then
    return false;
  end if;

  if p_field = 'size' then
    update public.order_items
    set size = clean_value
    where order_id = target_order_id and product_id = p_product_id;
  else
    update public.order_items
    set color = clean_value
    where order_id = target_order_id and product_id = p_product_id;
  end if;

  get diagnostics updated_count = row_count;
  return updated_count > 0;
end;
$$;

revoke all on function public.submit_order_option_fix(text, text, text, text) from public, anon, authenticated;
grant execute on function public.submit_order_option_fix(text, text, text, text) to service_role;

-- الغلاف العام: يتحقق من جلسة الزبون وملكية الطلب ثم يستدعي النواة —
-- نفس نمط submit_order_custom_fix في 20260711_harden_customer_payments.
create or replace function public.submit_order_option_fix(
  target_order_id text,
  p_product_id text,
  p_field text,
  p_value text,
  p_session_token text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if not exists (
    select 1 from public.orders where id = target_order_id and customer_id = target_customer_id
  ) then return false; end if;
  return public.submit_order_option_fix(target_order_id, p_product_id, p_field, p_value);
end;
$$;

revoke all on function public.submit_order_option_fix(text, text, text, text, text) from public;
grant execute on function public.submit_order_option_fix(text, text, text, text, text) to anon, authenticated;

-- ── (1) إخراج الفاتورة في JSON طلبات الزبون ────────────────────────────────
-- إعادة تعريف customer_orders_json بإضافة invoice، مع الإبقاء على حقول
-- التخصيص المضافة في 20260712000000 وصلاحيات التقوية (service_role فقط —
-- التطبيق يصل إليها عبر غلاف get_customer_account الموقّع بالجلسة).
create or replace function public.customer_orders_json(target_customer_id uuid, target_phone text)
returns jsonb
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', o.id,
      'customer', o.customer_name,
      'phone', o.phone,
      'city', o.city,
      'address', o.address,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', oi.product_id,
          'title', oi.title,
          'image', oi.image,
          'color', oi.color,
          'size', oi.size,
          'quantity', oi.quantity,
          'priceSyp', oi.price_syp,
          'sourceLink', oi.source_link,
          'customText', oi.custom_text,
          'customPhotoDataUrl', oi.custom_photo,
          'customPhotoNote', oi.custom_photo_note
        ) order by oi.created_at), '[]'::jsonb)
        from public.order_items oi
        where oi.order_id = o.id
      ),
      'total', o.total_syp,
      'paymentStatus', o.payment_status,
      'statusIndex', o.status_index,
      'qadmousNumber', o.qadmous_number,
      'createdAt', o.created_at,
      'paidAt', o.paid_at,
      'rating', o.rating,
      'ratingNote', o.rating_note,
      'paymentIssue', o.payment_issue,
      'paymentIssueNote', o.payment_issue_note,
      'extraAmountUsd', o.extra_amount_usd,
      'invoice', o.invoice,
      'groupId', o.group_id,
      'groupCode', o.group_code
    ) order by o.created_at desc), '[]'::jsonb)
  from public.orders o
  where (target_customer_id is not null and o.customer_id = target_customer_id)
     or (target_phone <> '' and o.phone = target_phone);
$$;

revoke all on function public.customer_orders_json(uuid, text) from public, anon, authenticated;
grant execute on function public.customer_orders_json(uuid, text) to service_role;
