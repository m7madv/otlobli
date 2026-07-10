-- Payment hardening v2
-- - server-issued customer sessions (only SHA-256 token hashes are stored)
-- - authenticated customer RPC overloads
-- - atomic wallet reservation during checkout
-- - correct SYP credit for USD wallet top-ups
-- - durable ShamCash event audit log

create extension if not exists pgcrypto;

create table if not exists public.customer_sessions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  phone text not null,
  token_hash text not null unique check (token_hash ~ '^[0-9a-f]{64}$'),
  expires_at timestamptz not null,
  revoked_at timestamptz,
  last_used_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists customer_sessions_customer_id_idx
  on public.customer_sessions (customer_id, created_at desc);
create index if not exists customer_sessions_phone_idx
  on public.customer_sessions (phone, created_at desc);
create index if not exists customer_sessions_expires_at_idx
  on public.customer_sessions (expires_at);
alter table public.customer_sessions enable row level security;

create table if not exists public.payment_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null default 'shamcash',
  event_id text not null unique,
  device_id text not null,
  package_name text not null,
  occurred_at timestamptz,
  received_at timestamptz not null default now(),
  notification_text text not null default '',
  raw_payload jsonb not null default '{}'::jsonb,
  status text not null default 'received'
    check (status in ('received', 'rejected', 'unmatched', 'ambiguous', 'matched', 'duplicate', 'error')),
  parsed_amount numeric(14, 2),
  parsed_currency text check (parsed_currency is null or parsed_currency in ('SYP', 'USD')),
  matched_type text,
  matched_id text,
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists payment_events_received_at_idx
  on public.payment_events (received_at desc);
create index if not exists payment_events_status_idx
  on public.payment_events (status, received_at desc);
alter table public.payment_events enable row level security;

alter table public.orders add column if not exists wallet_reserved_syp integer not null default 0;
alter table public.orders add column if not exists payment_destination text not null default '';

create or replace function public.create_customer_session(
  p_phone text,
  p_token_hash text,
  p_expires_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  cleaned_phone text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  target_customer_id uuid;
  new_session_id uuid;
begin
  if length(cleaned_phone) < 8 then
    raise exception 'invalid phone';
  end if;
  if coalesce(p_token_hash, '') !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid token hash';
  end if;
  if p_expires_at is null or p_expires_at <= now() or p_expires_at > now() + interval '90 days' then
    raise exception 'invalid session expiry';
  end if;

  select id into target_customer_id
  from public.customers
  where phone = cleaned_phone
  limit 1;

  if target_customer_id is null then
    target_customer_id := public.ensure_customer(cleaned_phone, 'عميل طلبية', 'دمشق', '', '', '');
  end if;

  delete from public.customer_sessions
  where expires_at <= now() or revoked_at is not null;

  insert into public.customer_sessions (customer_id, phone, token_hash, expires_at)
  values (target_customer_id, cleaned_phone, p_token_hash, p_expires_at)
  returning id into new_session_id;

  return new_session_id;
end;
$$;

revoke all on function public.create_customer_session(text, text, timestamptz) from public, anon, authenticated;
grant execute on function public.create_customer_session(text, text, timestamptz) to service_role;

create or replace function public.require_customer_session(
  p_session_token text,
  p_phone text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
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

  update public.customer_sessions
  set last_used_at = now()
  where id = found_session.id;

  return found_session.customer_id;
end;
$$;

revoke all on function public.require_customer_session(text, text) from public, anon, authenticated;
grant execute on function public.require_customer_session(text, text) to service_role;

create or replace function public.available_wallet_syp(p_customer_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  ledger_balance integer := 0;
  active_reservations integer := 0;
begin
  select coalesce(sum(amount_syp), 0)::integer into ledger_balance
  from public.wallet_transactions
  where customer_id = p_customer_id;

  select coalesce(sum(wallet_reserved_syp), 0)::integer into active_reservations
  from public.orders
  where customer_id = p_customer_id
    and payment_status = 'بانتظار الدفع'
    and wallet_reserved_syp > 0
    and (payment_expires_at is null or payment_expires_at > now());

  return greatest(ledger_balance - active_reservations, 0);
end;
$$;

revoke all on function public.available_wallet_syp(uuid) from public, anon, authenticated;
grant execute on function public.available_wallet_syp(uuid) to service_role;

create or replace function public.apply_order_wallet_reservation(p_order_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order public.orders%rowtype;
  account_phone text;
  usd_rate numeric;
  ledger_balance integer := 0;
begin
  select * into target_order
  from public.orders
  where id = p_order_id
  for update;

  if not found or target_order.wallet_reserved_syp <= 0 then
    return;
  end if;

  perform pg_advisory_xact_lock(hashtext('wallet-' || target_order.customer_id::text));
  if exists (
    select 1 from public.wallet_transactions
    where order_id = target_order.id and kind = 'order_payment'
  ) then
    return;
  end if;

  select coalesce(sum(amount_syp), 0)::integer into ledger_balance
  from public.wallet_transactions
  where customer_id = target_order.customer_id;
  if ledger_balance < target_order.wallet_reserved_syp then
    raise exception 'insufficient wallet balance at payment confirmation';
  end if;

  select phone into account_phone from public.customers where id = target_order.customer_id;
  select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
  usd_rate := coalesce(nullif(usd_rate, 0), 13000);

  insert into public.wallet_transactions (
    customer_id, phone, order_id, amount_syp, amount_usd,
    kind, note, created_by, metadata
  )
  values (
    target_order.customer_id,
    coalesce(account_phone, target_order.phone),
    target_order.id,
    -target_order.wallet_reserved_syp,
    -round(target_order.wallet_reserved_syp / usd_rate, 2),
    'order_payment',
    'خصم محجوز من المحفظة للطلب ' || target_order.id,
    'payment-transaction',
    jsonb_build_object('orderId', target_order.id, 'reservedSyp', target_order.wallet_reserved_syp)
  );
end;
$$;

revoke all on function public.apply_order_wallet_reservation(text) from public, anon, authenticated;
grant execute on function public.apply_order_wallet_reservation(text) to service_role;

create or replace function public.create_pending_order(
  order_payload jsonb,
  currency text,
  p_session_token text,
  p_wallet_spend_usd numeric
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order_id text := nullif(order_payload->>'id', '');
  target_customer_id uuid;
  target_group_id uuid := nullif(order_payload->>'groupId', '')::uuid;
  account_phone text;
  item_count integer := case
    when jsonb_typeof(order_payload->'items') = 'array' then jsonb_array_length(order_payload->'items')
    else 0
  end;
  order_total_syp integer := greatest(coalesce(nullif(order_payload->>'total', '')::integer, 0), 0);
  normalized_currency text := upper(coalesce(currency, ''));
  usd_rate numeric;
  available_syp integer;
  wallet_requested_syp integer := 0;
  remaining_syp integer;
  nominal_amount numeric;
  unit_step numeric;
  candidate_amount numeric;
  expires timestamptz := now() + interval '2 hours';
  attempt integer;
  max_attempts integer := 120;
begin
  if target_order_id is null then raise exception 'order id is required'; end if;
  if item_count = 0 then raise exception 'order items are required'; end if;
  if order_total_syp <= 0 then raise exception 'order total must be positive'; end if;
  if normalized_currency not in ('SYP', 'USD') then raise exception 'invalid currency'; end if;
  if coalesce(p_wallet_spend_usd, 0) < 0 then raise exception 'invalid wallet amount'; end if;

  target_customer_id := public.require_customer_session(p_session_token, null);
  select phone into account_phone from public.customers where id = target_customer_id;

  perform pg_advisory_xact_lock(hashtext('wallet-' || target_customer_id::text));

  select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
  usd_rate := coalesce(nullif(usd_rate, 0), 13000);
  available_syp := public.available_wallet_syp(target_customer_id);
  wallet_requested_syp := round(coalesce(p_wallet_spend_usd, 0) * usd_rate)::integer;

  if wallet_requested_syp > available_syp then raise exception 'insufficient wallet balance'; end if;
  if wallet_requested_syp > order_total_syp then raise exception 'wallet amount exceeds order total'; end if;
  remaining_syp := order_total_syp - wallet_requested_syp;

  perform pg_advisory_xact_lock(hashtext('shamcash-payment-' || normalized_currency));

  update public.orders
  set payment_status = 'فشل المطابقة'
  where payment_status = 'بانتظار الدفع'
    and payment_expires_at is not null
    and payment_expires_at <= now();
  update public.wallet_topups set status = 'منتهي'
  where status = 'بانتظار الدفع' and expires_at <= now();
  update public.order_issue_payments set status = 'منتهي'
  where status = 'بانتظار الدفع' and expires_at <= now();

  if remaining_syp = 0 then
    insert into public.orders (
      id, customer_id, customer_name, phone, city, address, total_syp,
      payment_status, status_index, qadmous_number, created_at, paid_at,
      payment_amount, payment_currency, payment_expires_at, payment_matched_by,
      group_id, group_code, wallet_reserved_syp, payment_destination
    )
    values (
      target_order_id, target_customer_id,
      coalesce(nullif(order_payload->>'customer', ''), 'عميل طلبية'),
      coalesce(nullif(order_payload->>'phone', ''), account_phone, 'غير محدد'),
      coalesce(nullif(order_payload->>'city', ''), 'غير محدد'),
      coalesce(nullif(order_payload->>'address', ''), 'عنوان غير مكتمل'),
      order_total_syp, 'مدفوع', 1, '', current_date, current_date,
      null, normalized_currency, now(), 'wallet-only',
      target_group_id, coalesce(order_payload->>'groupCode', ''),
      wallet_requested_syp, coalesce(order_payload->>'store', '')
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

    perform public.apply_order_wallet_reservation(target_order_id);
    insert into public.order_events (order_id, status_index, title, note)
    values (target_order_id, 1, 'تم تأكيد الدفع', 'تم دفع كامل الطلب من المحفظة');

    if target_group_id is not null then
      update public.cart_groups
      set status = 'ordered', payer_customer_id = target_customer_id
      where id = target_group_id;
    end if;

    return jsonb_build_object(
      'orderId', target_order_id,
      'paymentAmount', 0,
      'paymentCurrency', normalized_currency,
      'paymentExpiresAt', now(),
      'paymentStatus', 'مدفوع',
      'walletBalanceUsd', round(public.available_wallet_syp(target_customer_id) / usd_rate, 2)
    );
  end if;

  if normalized_currency = 'USD' then
    nominal_amount := round(remaining_syp / usd_rate, 2);
    unit_step := 0.01;
  else
    nominal_amount := remaining_syp;
    unit_step := 1;
  end if;

  for attempt in 0..max_attempts loop
    candidate_amount := nominal_amount - (attempt * unit_step);
    if candidate_amount <= 0 then exit; end if;

    if exists (
      select 1 from public.orders
      where payment_status = 'بانتظار الدفع'
        and payment_currency = normalized_currency
        and payment_amount = candidate_amount
        and (payment_expires_at is null or payment_expires_at > now())
    ) or exists (
      select 1 from public.wallet_topups
      where status = 'بانتظار الدفع'
        and payment_currency = normalized_currency
        and payment_amount = candidate_amount
        and expires_at > now()
    ) or exists (
      select 1 from public.order_issue_payments
      where status = 'بانتظار الدفع'
        and payment_currency = normalized_currency
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
        group_id, group_code, wallet_reserved_syp, payment_destination
      )
      values (
        target_order_id, target_customer_id,
        coalesce(nullif(order_payload->>'customer', ''), 'عميل طلبية'),
        coalesce(nullif(order_payload->>'phone', ''), account_phone, 'غير محدد'),
        coalesce(nullif(order_payload->>'city', ''), 'غير محدد'),
        coalesce(nullif(order_payload->>'address', ''), 'عنوان غير مكتمل'),
        order_total_syp, 'بانتظار الدفع', 0, '', current_date,
        candidate_amount, normalized_currency, expires,
        target_group_id, coalesce(order_payload->>'groupCode', ''),
        wallet_requested_syp, coalesce(order_payload->>'store', '')
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

      return jsonb_build_object(
        'orderId', target_order_id,
        'paymentAmount', candidate_amount,
        'paymentCurrency', normalized_currency,
        'paymentExpiresAt', expires,
        'paymentStatus', 'بانتظار الدفع',
        'walletBalanceUsd', round(public.available_wallet_syp(target_customer_id) / usd_rate, 2)
      );
    exception when unique_violation then
      continue;
    end;
  end loop;

  raise exception 'تعذر إيجاد مبلغ دفع فريد حالياً، حاول بعد دقيقة';
end;
$$;

revoke all on function public.create_pending_order(jsonb, text, text, numeric) from public;
grant execute on function public.create_pending_order(jsonb, text, text, numeric) to anon, authenticated;

create or replace function public.create_wallet_topup(
  p_phone text,
  p_name text,
  p_amount_usd numeric,
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  account_phone text;
  requested_usd numeric := round(coalesce(p_amount_usd, 0), 2);
  usd_rate numeric;
  credit_syp integer;
  candidate_amount numeric;
  expires timestamptz := now() + interval '5 minutes';
  attempt integer;
  inserted_topup_id uuid;
begin
  if requested_usd <= 0 then raise exception 'amount must be positive'; end if;
  target_customer_id := public.require_customer_session(p_session_token, p_phone);
  select phone into account_phone from public.customers where id = target_customer_id;

  if nullif(trim(coalesce(p_name, '')), '') is not null then
    update public.customers
    set name = trim(p_name), updated_at = now()
    where id = target_customer_id and (name = '' or name = 'عميل طلبية');
  end if;

  select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
  usd_rate := coalesce(nullif(usd_rate, 0), 13000);
  credit_syp := round(requested_usd * usd_rate)::integer;

  perform pg_advisory_xact_lock(hashtext('shamcash-payment-USD'));
  update public.orders set payment_status = 'فشل المطابقة'
  where payment_status = 'بانتظار الدفع'
    and payment_expires_at is not null and payment_expires_at <= now();
  update public.wallet_topups set status = 'منتهي'
  where status = 'بانتظار الدفع' and expires_at <= now();
  update public.order_issue_payments set status = 'منتهي'
  where status = 'بانتظار الدفع' and expires_at <= now();

  for attempt in 0..120 loop
    candidate_amount := requested_usd - (attempt * 0.01);
    if candidate_amount <= 0 then exit; end if;

    if exists (
      select 1 from public.orders
      where payment_status = 'بانتظار الدفع' and payment_currency = 'USD'
        and payment_amount = candidate_amount
        and (payment_expires_at is null or payment_expires_at > now())
    ) or exists (
      select 1 from public.wallet_topups
      where status = 'بانتظار الدفع' and payment_currency = 'USD'
        and payment_amount = candidate_amount and expires_at > now()
    ) or exists (
      select 1 from public.order_issue_payments
      where status = 'بانتظار الدفع' and payment_currency = 'USD'
        and payment_amount = candidate_amount and expires_at > now()
    ) then
      continue;
    end if;

    begin
      insert into public.wallet_topups (
        customer_id, phone, requested_amount_syp, payment_amount,
        payment_currency, status, expires_at, metadata
      )
      values (
        target_customer_id, account_phone, credit_syp, candidate_amount,
        'USD', 'بانتظار الدفع', expires,
        jsonb_build_object('requestedUsd', requested_usd, 'usdRate', usd_rate)
      )
      returning id into inserted_topup_id;

      return jsonb_build_object(
        'topUpId', inserted_topup_id,
        'paymentAmount', candidate_amount,
        'paymentCurrency', 'USD',
        'paymentExpiresAt', expires,
        'creditAmountSyp', credit_syp
      );
    exception when unique_violation then
      continue;
    end;
  end loop;

  raise exception 'تعذر إيجاد مبلغ شحن فريد حالياً، حاول بعد دقيقة';
end;
$$;

revoke all on function public.create_wallet_topup(text, text, numeric, text) from public;
grant execute on function public.create_wallet_topup(text, text, numeric, text) to anon, authenticated;

create or replace function public.create_order_issue_payment(
  p_order_id text,
  p_amount_usd numeric,
  p_currency text,
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if not exists (
    select 1 from public.orders
    where id = nullif(p_order_id, '') and customer_id = target_customer_id
  ) then
    raise exception 'order not found';
  end if;
  perform pg_advisory_xact_lock(hashtext('shamcash-payment-' || upper(coalesce(p_currency, ''))));
  return public.create_order_issue_payment(p_order_id, p_amount_usd, upper(p_currency));
end;
$$;

revoke all on function public.create_order_issue_payment(text, numeric, text, text) from public;
grant execute on function public.create_order_issue_payment(text, numeric, text, text) to anon, authenticated;

create or replace function public.confirm_payment_by_amount(
  match_amount numeric,
  match_currency text,
  notification_text text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  matched_order public.orders%rowtype;
  match_count integer;
begin
  select count(*) into match_count
  from public.orders
  where payment_status = 'بانتظار الدفع'
    and payment_currency = match_currency
    and payment_amount = match_amount
    and (payment_expires_at is null or payment_expires_at > now());

  if match_count = 0 then return jsonb_build_object('matched', false, 'reason', 'not_found'); end if;
  if match_count > 1 then return jsonb_build_object('matched', false, 'reason', 'ambiguous'); end if;

  select * into matched_order
  from public.orders
  where payment_status = 'بانتظار الدفع'
    and payment_currency = match_currency
    and payment_amount = match_amount
    and (payment_expires_at is null or payment_expires_at > now())
  limit 1
  for update;

  perform public.apply_order_wallet_reservation(matched_order.id);

  update public.orders
  set payment_status = 'مدفوع', status_index = 1, paid_at = current_date,
      payment_matched_by = 'sham-cash-webhook'
  where id = matched_order.id;

  if matched_order.group_id is not null then
    update public.cart_groups
    set status = 'ordered', payer_customer_id = matched_order.customer_id
    where id = matched_order.group_id;
  end if;

  insert into public.order_events (order_id, status_index, title, note)
  values (matched_order.id, 1, 'تم تأكيد الدفع', 'تم تأكيد الدفع تلقائياً من إشعار شام كاش');

  return jsonb_build_object(
    'matched', true,
    'orderId', matched_order.id,
    'customerName', matched_order.customer_name,
    'phone', matched_order.phone
  );
end;
$$;

revoke all on function public.confirm_payment_by_amount(numeric, text, text) from public, anon, authenticated;
grant execute on function public.confirm_payment_by_amount(numeric, text, text) to service_role;

create or replace function public.confirm_wallet_topup_by_amount(
  match_amount numeric,
  match_currency text,
  raw_notification_text text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  matched_topup public.wallet_topups%rowtype;
  match_count integer;
  credit_amount integer;
  wallet_balance integer := 0;
begin
  update public.wallet_topups set status = 'منتهي'
  where status = 'بانتظار الدفع' and expires_at <= now();

  select count(*) into match_count
  from public.wallet_topups
  where status = 'بانتظار الدفع'
    and payment_currency = match_currency
    and payment_amount = match_amount
    and expires_at > now();

  if match_count = 0 then return jsonb_build_object('matched', false, 'reason', 'not_found'); end if;
  if match_count > 1 then return jsonb_build_object('matched', false, 'reason', 'ambiguous'); end if;

  select * into matched_topup
  from public.wallet_topups
  where status = 'بانتظار الدفع'
    and payment_currency = match_currency
    and payment_amount = match_amount
    and expires_at > now()
  limit 1
  for update;

  credit_amount := greatest(matched_topup.requested_amount_syp, 0);
  if credit_amount <= 0 then raise exception 'invalid wallet top-up credit'; end if;

  update public.wallet_topups
  set status = 'مدفوع', paid_at = now(),
      notification_text = left(coalesce(raw_notification_text, ''), 1200)
  where id = matched_topup.id;

  insert into public.wallet_transactions (
    customer_id, phone, amount_syp, amount_usd, kind, note, created_by, metadata
  )
  values (
    matched_topup.customer_id, matched_topup.phone, credit_amount,
    case when matched_topup.payment_currency = 'USD' then matched_topup.payment_amount else 0 end,
    'wallet_topup', 'شحن محفظة عبر شام كاش', 'sham-cash-webhook',
    jsonb_build_object(
      'topUpId', matched_topup.id,
      'paymentAmount', matched_topup.payment_amount,
      'paymentCurrency', matched_topup.payment_currency,
      'notificationText', left(coalesce(raw_notification_text, ''), 1200)
    )
  );

  select coalesce(sum(amount_syp), 0)::integer into wallet_balance
  from public.wallet_transactions
  where customer_id = matched_topup.customer_id;

  return jsonb_build_object(
    'matched', true, 'type', 'wallet_topup',
    'topUpId', matched_topup.id, 'phone', matched_topup.phone,
    'creditAmountSyp', credit_amount, 'walletBalanceSyp', wallet_balance
  );
end;
$$;

revoke all on function public.confirm_wallet_topup_by_amount(numeric, text, text) from public, anon, authenticated;
grant execute on function public.confirm_wallet_topup_by_amount(numeric, text, text) to service_role;

create or replace function public.get_customer_account(p_phone text, p_session_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  payload jsonb;
  available_syp integer;
begin
  target_customer_id := public.require_customer_session(p_session_token, p_phone);
  payload := public.get_customer_account(p_phone);
  available_syp := public.available_wallet_syp(target_customer_id);
  payload := payload || jsonb_build_object('walletBalanceSyp', available_syp);
  if jsonb_typeof(payload->'profile') = 'object' then
    payload := jsonb_set(
      payload,
      '{profile}',
      (payload->'profile') || jsonb_build_object('walletBalanceSyp', available_syp),
      true
    );
  end if;
  return payload;
end;
$$;

revoke all on function public.get_customer_account(text, text) from public;
grant execute on function public.get_customer_account(text, text) to anon, authenticated;

create or replace function public.upsert_customer_profile(
  p_phone text,
  p_name text,
  p_governorate text,
  p_session_token text,
  p_qadmous_branch text default '',
  p_city text default '',
  p_details text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_customer_session(p_session_token, p_phone);
  perform public.upsert_customer_profile(
    p_phone, p_name, p_governorate, p_qadmous_branch, p_city, p_details
  );
  return public.get_customer_account(p_phone, p_session_token);
end;
$$;

revoke all on function public.upsert_customer_profile(text, text, text, text, text, text, text) from public;
grant execute on function public.upsert_customer_profile(text, text, text, text, text, text, text) to anon, authenticated;

create or replace function public.update_customer_preferences(
  p_phone text,
  p_session_token text,
  p_pickup_label text default '',
  p_notification_prefs jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_customer_session(p_session_token, p_phone);
  perform public.update_customer_preferences(p_phone, p_pickup_label, p_notification_prefs);
  return public.get_customer_account(p_phone, p_session_token);
end;
$$;

revoke all on function public.update_customer_preferences(text, text, text, jsonb) from public;
grant execute on function public.update_customer_preferences(text, text, text, jsonb) to anon, authenticated;

create or replace function public.get_wallet_balance_usd(p_phone text, p_session_token text)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  usd_rate numeric;
begin
  target_customer_id := public.require_customer_session(p_session_token, p_phone);
  select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
  usd_rate := coalesce(nullif(usd_rate, 0), 13000);
  return round(public.available_wallet_syp(target_customer_id) / usd_rate, 2);
end;
$$;

revoke all on function public.get_wallet_balance_usd(text, text) from public;
grant execute on function public.get_wallet_balance_usd(text, text) to anon, authenticated;

create or replace function public.get_wallet_topup_status(
  target_topup_id text,
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  found_topup public.wallet_topups%rowtype;
  wallet_balance integer := 0;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);

  update public.wallet_topups set status = 'منتهي'
  where id = nullif(target_topup_id, '')::uuid
    and status = 'بانتظار الدفع' and expires_at <= now();

  select * into found_topup
  from public.wallet_topups
  where id = nullif(target_topup_id, '')::uuid
    and customer_id = target_customer_id;

  if not found then return jsonb_build_object('found', false); end if;
  wallet_balance := public.available_wallet_syp(target_customer_id);

  return jsonb_build_object(
    'found', true,
    'status', found_topup.status,
    'paidAt', found_topup.paid_at,
    'paymentAmount', found_topup.payment_amount,
    'paymentCurrency', found_topup.payment_currency,
    'paymentExpiresAt', found_topup.expires_at,
    'creditAmountSyp', greatest(found_topup.requested_amount_syp, 0),
    'walletBalanceSyp', wallet_balance
  );
end;
$$;

revoke all on function public.get_wallet_topup_status(text, text) from public;
grant execute on function public.get_wallet_topup_status(text, text) to anon, authenticated;

create or replace function public.get_order_payment_status(
  target_order_id text,
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  found_order public.orders%rowtype;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  select * into found_order
  from public.orders
  where id = target_order_id and customer_id = target_customer_id;
  if not found then return jsonb_build_object('found', false); end if;

  return jsonb_build_object(
    'found', true,
    'paymentStatus', found_order.payment_status,
    'statusIndex', found_order.status_index,
    'paidAt', found_order.paid_at,
    'paymentAmount', found_order.payment_amount,
    'paymentCurrency', found_order.payment_currency,
    'paymentExpiresAt', found_order.payment_expires_at,
    'qadmousNumber', found_order.qadmous_number,
    'paymentIssue', found_order.payment_issue,
    'paymentIssueNote', found_order.payment_issue_note,
    'extraAmountUsd', found_order.extra_amount_usd
  );
end;
$$;

revoke all on function public.get_order_payment_status(text, text) from public;
grant execute on function public.get_order_payment_status(text, text) to anon, authenticated;

create or replace function public.redeem_coupon(
  p_code text,
  p_phone text,
  p_device_id text,
  p_store text,
  p_subtotal_syp integer,
  p_usd_rate numeric,
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_customer_session(p_session_token, p_phone);
  return public.redeem_coupon(
    p_code, p_phone, p_device_id, p_store, p_subtotal_syp, p_usd_rate
  );
end;
$$;

revoke all on function public.redeem_coupon(text, text, text, text, integer, numeric, text) from public;
grant execute on function public.redeem_coupon(text, text, text, text, integer, numeric, text) to anon, authenticated;

create or replace function public.submit_order_rating(
  target_order_id text,
  p_stars integer,
  p_note text,
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
  return public.submit_order_rating(target_order_id, p_stars, p_note);
end;
$$;

revoke all on function public.submit_order_rating(text, integer, text, text) from public;
grant execute on function public.submit_order_rating(text, integer, text, text) to anon, authenticated;

create or replace function public.submit_order_custom_fix(
  target_order_id text,
  p_product_id text,
  p_custom_photo text,
  p_custom_text text,
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
  return public.submit_order_custom_fix(
    target_order_id, p_product_id, p_custom_photo, p_custom_text
  );
end;
$$;

revoke all on function public.submit_order_custom_fix(text, text, text, text, text) from public;
grant execute on function public.submit_order_custom_fix(text, text, text, text, text) to anon, authenticated;

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

-- Remove all direct anonymous access to the legacy phone-trusting RPCs.
revoke all on function public.submit_order(jsonb) from anon, authenticated;
revoke all on function public.create_pending_order(jsonb, text) from anon, authenticated;
revoke all on function public.create_order_issue_payment(text, numeric, text) from anon, authenticated;
revoke all on function public.create_wallet_topup(text, text, integer) from anon, authenticated;
revoke all on function public.create_wallet_topup(text, text, numeric) from anon, authenticated;
revoke all on function public.get_wallet_topup_status(text) from anon, authenticated;
revoke all on function public.get_order_payment_status(text) from anon, authenticated;
revoke all on function public.get_customer_account(text) from anon, authenticated;
revoke all on function public.get_wallet_balance_usd(text) from anon, authenticated;
revoke all on function public.wallet_spend(text, numeric, text) from anon, authenticated;
revoke all on function public.upsert_customer_profile(text, text, text, text, text, text) from anon, authenticated;
revoke all on function public.update_customer_preferences(text, text, jsonb) from anon, authenticated;
revoke all on function public.redeem_coupon(text, text, text, text, integer, numeric) from anon, authenticated;
revoke all on function public.submit_order_rating(text, integer, text) from anon, authenticated;
revoke all on function public.submit_order_custom_fix(text, text, text, text) from anon, authenticated;
revoke all on function public.ensure_customer(text, text, text, text, text, text) from anon, authenticated;
revoke all on function public.upsert_customer_from_order(jsonb) from anon, authenticated;
revoke all on function public.customer_orders_json(uuid, text) from anon, authenticated;

grant execute on function public.submit_order(jsonb) to service_role;
grant execute on function public.create_pending_order(jsonb, text) to service_role;
grant execute on function public.create_order_issue_payment(text, numeric, text) to service_role;
grant execute on function public.create_wallet_topup(text, text, integer) to service_role;
grant execute on function public.create_wallet_topup(text, text, numeric) to service_role;
grant execute on function public.get_wallet_topup_status(text) to service_role;
grant execute on function public.get_order_payment_status(text) to service_role;
grant execute on function public.get_customer_account(text) to service_role;
grant execute on function public.get_wallet_balance_usd(text) to service_role;
grant execute on function public.wallet_spend(text, numeric, text) to service_role;
grant execute on function public.upsert_customer_profile(text, text, text, text, text, text) to service_role;
grant execute on function public.update_customer_preferences(text, text, jsonb) to service_role;
grant execute on function public.redeem_coupon(text, text, text, text, integer, numeric) to service_role;
grant execute on function public.submit_order_rating(text, integer, text) to service_role;
grant execute on function public.submit_order_custom_fix(text, text, text, text) to service_role;
grant execute on function public.ensure_customer(text, text, text, text, text, text) to service_role;
grant execute on function public.upsert_customer_from_order(jsonb) to service_role;
grant execute on function public.customer_orders_json(uuid, text) to service_role;
