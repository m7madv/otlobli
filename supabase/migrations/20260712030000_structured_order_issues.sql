-- v63: نظام مشاكل احترافي متعدد لكل طلب.
-- بدل ملاحظة نصية مفردة (paymentIssueNote) نضيف مصفوفة issues منظمة:
-- كل مشكلة {id, type, itemId, note, requiredSize, options[], amountUsd,
-- resolved, resolvedValue}. المشرف يضيف عدة مشاكل، والزبون يحل كل واحدة
-- من طلباتي. مسار الدفع المقوّى (paymentIssue/extraAmountUsd/الويبهوك) يبقى
-- كما هو — المشرف/الواجهة يشتقّانه من مشاكل نوع payment للتوافق.

alter table public.orders
  add column if not exists issues jsonb not null default '[]'::jsonb;

-- يعلّم مشكلة بعينها كمحلولة بقيمة الزبون (بعد أن يحلها فعلياً عبر RPC
-- المختصة: option_fix/custom_fix/الدفع). يحدّث فقط عنصر issues المطابق
-- بالـid داخل مصفوفة الطلب. نمط الغلاف الموقّع بالجلسة نفسه.
create or replace function public.submit_order_issue_resolve(
  target_order_id text,
  p_issue_id text,
  p_resolved_value text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  if coalesce(target_order_id, '') = '' or coalesce(p_issue_id, '') = '' then
    return false;
  end if;

  update public.orders o
  set issues = (
    select jsonb_agg(
      case when elem->>'id' = p_issue_id
        then elem || jsonb_build_object('resolved', true, 'resolvedValue', left(coalesce(p_resolved_value, ''), 200))
        else elem
      end
    )
    from jsonb_array_elements(o.issues) elem
  )
  where o.id = target_order_id
    and jsonb_typeof(o.issues) = 'array'
    and exists (
      select 1 from jsonb_array_elements(o.issues) e where e->>'id' = p_issue_id
    );

  get diagnostics updated_count = row_count;
  return updated_count > 0;
end;
$$;

revoke all on function public.submit_order_issue_resolve(text, text, text) from public, anon, authenticated;
grant execute on function public.submit_order_issue_resolve(text, text, text) to service_role;

create or replace function public.submit_order_issue_resolve(
  target_order_id text,
  p_issue_id text,
  p_resolved_value text,
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
  return public.submit_order_issue_resolve(target_order_id, p_issue_id, p_resolved_value);
end;
$$;

revoke all on function public.submit_order_issue_resolve(text, text, text, text) from public;
grant execute on function public.submit_order_issue_resolve(text, text, text, text) to anon, authenticated;

-- إضافة issues لإخراج طلبات الزبون (مع الإبقاء على كل الحقول السابقة).
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
      'issues', o.issues,
      'groupId', o.group_id,
      'groupCode', o.group_code
    ) order by o.created_at desc), '[]'::jsonb)
  from public.orders o
  where (target_customer_id is not null and o.customer_id = target_customer_id)
     or (target_phone <> '' and o.phone = target_phone);
$$;

revoke all on function public.customer_orders_json(uuid, text) from public, anon, authenticated;
grant execute on function public.customer_orders_json(uuid, text) to service_role;
