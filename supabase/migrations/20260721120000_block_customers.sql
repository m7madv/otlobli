-- حظر المستخدمين (لوحة الإدارة): عمود blocked + حرّاس مركزيون يمنعون المحظور
-- من الدخول (get_customer_account/require_customer_session) ومن الطلب وكل إجراء
-- موثّق (require_customer_session) ومن حفظ الملف (ensure_customer).

alter table public.customers add column if not exists blocked boolean not null default false;

create or replace function public.ensure_customer(
  p_phone text,
  p_name text default '',
  p_governorate text default 'دمشق',
  p_qadmous_branch text default '',
  p_city text default '',
  p_details text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  cleaned_phone text := regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g');
  validated_name text := '';
  target_id uuid;
begin
  if cleaned_phone = '' then
    raise exception 'phone is required';
  end if;

  -- حظر المستخدم: لو كان الرقم موجوداً ومحظوراً، امنع الدخول والطلب معاً. رقم جديد
  -- لا يمكن أن يكون محظوراً (غير موجود بعد)، فهذا لا يؤثّر على المستخدمين الجدد.
  if exists (select 1 from public.customers where phone = cleaned_phone and blocked = true) then
    raise exception 'customer_blocked' using errcode = 'P0001';
  end if;

  if trim(coalesce(p_name, '')) <> '' then
    validated_name := public.validate_customer_full_name(p_name);
  end if;

  insert into public.customers (phone, name, governorate, qadmous_branch, city, details)
  values (
    cleaned_phone,
    nullif(validated_name, ''),
    coalesce(nullif(trim(coalesce(p_governorate, '')), ''), 'دمشق'),
    trim(coalesce(p_qadmous_branch, '')),
    trim(coalesce(p_city, '')),
    trim(coalesce(p_details, ''))
  )
  on conflict (phone) do update set
    name = coalesce(nullif(excluded.name, ''), public.customers.name),
    governorate = coalesce(nullif(excluded.governorate, ''), public.customers.governorate, 'دمشق'),
    qadmous_branch = coalesce(nullif(excluded.qadmous_branch, ''), public.customers.qadmous_branch, ''),
    city = coalesce(nullif(excluded.city, ''), public.customers.city, ''),
    details = coalesce(nullif(excluded.details, ''), public.customers.details, ''),
    updated_at = now()
  returning id into target_id;

  return target_id;
end;
$$;

revoke all on function public.ensure_customer(text, text, text, text, text, text) from public;
grant execute on function public.ensure_customer(text, text, text, text, text, text) to anon, authenticated, service_role;


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

  -- حظر المستخدم: يُرفض المحظور عند تحميل الحساب (الدخول). التطبيق يلتقط
  -- customer_blocked ويعرض تنبيهاً ويمنع الدخول.
  if found and found_customer.blocked = true then
    raise exception 'customer_blocked' using errcode = 'P0001';
  end if;

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

create or replace function public.require_customer_session(
  p_session_token text,
  p_phone text default null
)
returns uuid
language plpgsql
security definer
set search_path = extensions, public, pg_temp
as $$
declare
  token_digest text := encode(digest(coalesce(p_session_token, ''), 'sha256'), 'hex');
  cleaned_phone text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  found_session public.customer_sessions%rowtype;
begin
  if length(coalesce(p_session_token, '')) < 32 then
    raise exception 'invalid customer session';
  end if;

  select * into found_session
  from public.customer_sessions
  where token_hash = token_digest
    and revoked_at is null
    and expires_at > now()
  limit 1
  for update;

  if not found then
    raise exception 'invalid customer session';
  end if;
  if cleaned_phone <> '' and found_session.phone <> cleaned_phone then
    raise exception 'customer session phone mismatch';
  end if;

  -- حظر المستخدم: يُمنع المحظور من كل إجراء موثّق (طلب/محفظة/حفظ ملف...) لأن
  -- جميعها تمرّ من هنا. الرسالة customer_blocked يلتقطها التطبيق ويعرض تنبيهاً.
  if exists (select 1 from public.customers where id = found_session.customer_id and blocked = true) then
    raise exception 'customer_blocked' using errcode = 'P0001';
  end if;

  update public.customer_sessions
  set last_used_at = now()
  where id = found_session.id;

  return found_session.customer_id;
end;
$$;

revoke all on function public.require_customer_session(text, text) from public, anon, authenticated;
grant execute on function public.require_customer_session(text, text) to service_role;
