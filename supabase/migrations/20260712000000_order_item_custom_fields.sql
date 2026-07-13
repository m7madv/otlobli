-- v59: حقول التخصيص (نقش/صورة) لعناصر الطلب.
-- المشكلة: التطبيق يرسل customText/customPhotoDataUrl داخل عناصر الطلب،
-- لكن submit_order/create_pending_order يُسقطانها عند الإدراج في order_items
-- (أعمدة ثابتة) — فلا تصل النقوش ولا الصور للوحة الإدارة إطلاقاً.
-- الحل: أعمدة جديدة + تحديث دالتي الإدراج + إخراجها في customer_orders_json
-- + دالة submit_order_custom_fix ليصحح الزبون صورة/نص التخصيص من التطبيق
-- (تدفق "مشكلة قياس الصورة" الذي يحدده المشرف من لوحة الإدارة).

alter table public.order_items
  add column if not exists custom_text text not null default '',
  add column if not exists custom_photo text not null default '',
  add column if not exists custom_photo_note text not null default '';

create or replace function public.submit_order(order_payload jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order_id text := nullif(order_payload->>'id', '');
  item_count integer := coalesce(jsonb_array_length(order_payload->'items'), 0);
  target_status_index integer := coalesce(nullif(order_payload->>'statusIndex', '')::integer, 0);
  target_paid_at date := null;
  target_customer_id uuid;
  target_group_id uuid := nullif(order_payload->>'groupId', '')::uuid;
begin
  if target_order_id is null then
    raise exception 'order id is required';
  end if;

  if item_count = 0 then
    raise exception 'order items are required';
  end if;

  if nullif(order_payload->>'paidAt', '') is not null then
    target_paid_at := (order_payload->>'paidAt')::date;
  end if;

  target_customer_id := public.upsert_customer_from_order(order_payload);

  insert into public.orders (
    id,
    customer_id,
    customer_name,
    phone,
    city,
    address,
    total_syp,
    payment_status,
    status_index,
    qadmous_number,
    created_at,
    paid_at,
    group_id,
    group_code
  )
  values (
    target_order_id,
    target_customer_id,
    coalesce(nullif(order_payload->>'customer', ''), 'عميل طلبية'),
    coalesce(nullif(order_payload->>'phone', ''), 'غير محدد'),
    coalesce(nullif(order_payload->>'city', ''), 'غير محدد'),
    coalesce(nullif(order_payload->>'address', ''), 'عنوان غير مكتمل'),
    greatest(coalesce(nullif(order_payload->>'total', '')::integer, 0), 0),
    coalesce(nullif(order_payload->>'paymentStatus', ''), 'بانتظار الدفع'),
    target_status_index,
    coalesce(order_payload->>'qadmousNumber', ''),
    coalesce(nullif(order_payload->>'createdAt', '')::date, current_date),
    target_paid_at,
    target_group_id,
    coalesce(order_payload->>'groupCode', '')
  );

  insert into public.order_items (
    order_id,
    product_id,
    title,
    image,
    color,
    size,
    quantity,
    price_syp,
    source_link,
    custom_text,
    custom_photo,
    custom_photo_note
  )
  select
    target_order_id,
    item.id,
    item.title,
    item.image,
    item.color,
    item.size,
    greatest(coalesce(item.quantity, 1), 1),
    greatest(coalesce(item."priceSyp", 0), 0),
    item."sourceLink",
    coalesce(item."customText", ''),
    coalesce(item."customPhotoDataUrl", ''),
    coalesce(item."customPhotoNote", '')
  from jsonb_to_recordset(order_payload->'items') as item(
    id text,
    title text,
    image text,
    color text,
    size text,
    quantity integer,
    "priceSyp" integer,
    "sourceLink" text,
    "customText" text,
    "customPhotoDataUrl" text,
    "customPhotoNote" text
  );

  insert into public.order_events (order_id, status_index, title, note)
  values (
    target_order_id,
    target_status_index,
    'تم إنشاء الطلب',
    'تم إنشاء الطلب من تطبيق طلبية'
  );

  if target_group_id is not null then
    update public.cart_groups
    set status = 'ordered',
        payer_customer_id = target_customer_id
    where id = target_group_id;
  end if;

  return target_order_id;
end;
$$;

revoke all on function public.submit_order(jsonb) from public;
grant execute on function public.submit_order(jsonb) to anon, authenticated;

create or replace function public.create_pending_order(order_payload jsonb, currency text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order_id text := nullif(order_payload->>'id', '');
  item_count integer := coalesce(jsonb_array_length(order_payload->'items'), 0);
  order_total_syp numeric := greatest(coalesce(nullif(order_payload->>'total', '')::numeric, 0), 0);
  usd_rate numeric;
  nominal_amount numeric;
  unit_step numeric;
  candidate_amount numeric;
  expires timestamptz := now() + interval '2 hours';
  attempt integer;
  max_attempts integer := 40;
  target_customer_id uuid;
  target_group_id uuid := nullif(order_payload->>'groupId', '')::uuid;
begin
  if currency not in ('SYP', 'USD') then
    raise exception 'invalid currency';
  end if;

  if target_order_id is null then
    raise exception 'order id is required';
  end if;

  if item_count = 0 then
    raise exception 'order items are required';
  end if;

  if currency = 'USD' then
    select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
    usd_rate := coalesce(usd_rate, 13000);
    nominal_amount := round(order_total_syp / usd_rate, 2);
    unit_step := 0.01;
  else
    nominal_amount := order_total_syp;
    unit_step := 1;
  end if;

  target_customer_id := public.upsert_customer_from_order(order_payload);

  update public.wallet_topups
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and expires_at <= now();

  for attempt in 0..max_attempts loop
    candidate_amount := nominal_amount - (attempt * unit_step);
    if candidate_amount <= 0 then
      exit;
    end if;

    if exists (
      select 1
      from public.wallet_topups
      where status = 'بانتظار الدفع'
        and payment_currency = currency
        and payment_amount = candidate_amount
        and expires_at > now()
    ) then
      continue;
    end if;

    if exists (
      select 1
      from public.order_issue_payments
      where status = 'ط¨ط§ظ†طھط¸ط§ط± ط§ظ„ط¯ظپط¹'
        and payment_currency = currency
        and payment_amount = candidate_amount
        and expires_at > now()
    ) then
      continue;
    end if;

    begin
      insert into public.orders (
        id, customer_id, customer_name, phone, city, address, total_syp,
        payment_status, status_index, qadmous_number, created_at,
        payment_amount, payment_currency, payment_expires_at,
        group_id, group_code
      )
      values (
        target_order_id,
        target_customer_id,
        coalesce(nullif(order_payload->>'customer', ''), 'عميل طلبية'),
        coalesce(nullif(order_payload->>'phone', ''), 'غير محدد'),
        coalesce(nullif(order_payload->>'city', ''), 'غير محدد'),
        coalesce(nullif(order_payload->>'address', ''), 'عنوان غير مكتمل'),
        order_total_syp::integer,
        'بانتظار الدفع',
        0,
        '',
        current_date,
        candidate_amount,
        currency,
        expires,
        target_group_id,
        coalesce(order_payload->>'groupCode', '')
      );

      insert into public.order_items (
        order_id, product_id, title, image, color, size, quantity, price_syp, source_link,
        custom_text, custom_photo, custom_photo_note
      )
      select
        target_order_id, item.id, item.title, item.image, item.color, item.size,
        greatest(coalesce(item.quantity, 1), 1), greatest(coalesce(item."priceSyp", 0), 0), item."sourceLink",
        coalesce(item."customText", ''), coalesce(item."customPhotoDataUrl", ''), coalesce(item."customPhotoNote", '')
      from jsonb_to_recordset(order_payload->'items') as item(
        id text, title text, image text, color text, size text,
        quantity integer, "priceSyp" integer, "sourceLink" text,
        "customText" text, "customPhotoDataUrl" text, "customPhotoNote" text
      );

      insert into public.order_events (order_id, status_index, title, note)
      values (target_order_id, 0, 'بانتظار الدفع', 'تم إنشاء الطلب وبانتظار تحويل شام كاش');

      if target_group_id is not null then
        update public.cart_groups
        set status = 'ordered',
            payer_customer_id = target_customer_id
        where id = target_group_id;
      end if;

      return jsonb_build_object(
        'orderId', target_order_id,
        'paymentAmount', candidate_amount,
        'paymentCurrency', currency,
        'paymentExpiresAt', expires
      );
    exception when unique_violation then
      continue;
    end;
  end loop;

  raise exception 'تعذر إيجاد مبلغ دفع فريد حالياً، حاول بعد دقيقة';
end;
$$;

revoke all on function public.create_pending_order(jsonb, text) from public;
grant execute on function public.create_pending_order(jsonb, text) to anon, authenticated;

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
      'groupId', o.group_id,
      'groupCode', o.group_code
    ) order by o.created_at desc), '[]'::jsonb)
  from public.orders o
  where (target_customer_id is not null and o.customer_id = target_customer_id)
     or (target_phone <> '' and o.phone = target_phone);
$$;

revoke all on function public.customer_orders_json(uuid, text) from public;
grant execute on function public.customer_orders_json(uuid, text) to anon, authenticated, service_role;

-- يصحح الزبون صورة/نص التخصيص لعنصر في طلبه (تدفق "مشكلة قياس الصورة"):
-- يحدّث فقط حقول التخصيص، ولا يمس السعر/الكمية/الحالة. تمريره فارغاً يُبقي
-- القيمة الحالية. نفس مستوى حماية submit_order_rating (معرفة رقم الطلب).
create or replace function public.submit_order_custom_fix(
  target_order_id text,
  p_product_id text,
  p_custom_photo text,
  p_custom_text text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  if coalesce(target_order_id, '') = '' or coalesce(p_product_id, '') = '' then
    return false;
  end if;

  update public.order_items
  set custom_photo = coalesce(nullif(p_custom_photo, ''), custom_photo),
      custom_text = coalesce(nullif(p_custom_text, ''), custom_text)
  where order_id = target_order_id
    and product_id = p_product_id;

  get diagnostics updated_count = row_count;
  return updated_count > 0;
end;
$$;

revoke all on function public.submit_order_custom_fix(text, text, text, text) from public;
grant execute on function public.submit_order_custom_fix(text, text, text, text) to anon, authenticated;
