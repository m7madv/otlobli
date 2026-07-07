create table if not exists public.order_issue_payments (
  id uuid primary key default gen_random_uuid(),
  order_id text not null references public.orders(id) on delete cascade,
  payment_amount numeric(14, 2) not null check (payment_amount > 0),
  payment_currency text not null default 'SYP' check (payment_currency in ('SYP', 'USD')),
  requested_amount_usd numeric(14, 2) not null default 0,
  status text not null default 'بانتظار الدفع' check (status in ('بانتظار الدفع', 'مدفوع', 'منتهي')),
  notification_text text not null default '',
  paid_at timestamptz,
  expires_at timestamptz not null default now() + interval '5 minutes',
  created_at timestamptz not null default now()
);

create unique index if not exists order_issue_payments_pending_amount_uidx
  on public.order_issue_payments (payment_currency, payment_amount)
  where status = 'بانتظار الدفع';

create index if not exists order_issue_payments_order_id_idx on public.order_issue_payments (order_id, created_at desc);
create index if not exists order_issue_payments_status_idx on public.order_issue_payments (status, expires_at);

alter table public.order_issue_payments enable row level security;

create or replace function public.create_order_issue_payment(
  p_order_id text,
  p_amount_usd numeric,
  p_currency text default 'SYP'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  found_order public.orders%rowtype;
  usd_rate numeric;
  nominal_amount numeric;
  unit_step numeric;
  candidate_amount numeric;
  expires timestamptz := now() + interval '5 minutes';
  attempt integer;
  max_attempts integer := 40;
  new_payment_id uuid;
begin
  if p_currency not in ('SYP', 'USD') then
    raise exception 'invalid currency';
  end if;

  select * into found_order
  from public.orders
  where id = nullif(p_order_id, '');

  if not found then
    raise exception 'order not found';
  end if;

  if found_order.payment_issue is not true then
    raise exception 'no active payment issue';
  end if;

  if greatest(coalesce(p_amount_usd, 0), coalesce(found_order.extra_amount_usd, 0)) <= 0 then
    raise exception 'payment amount is required';
  end if;

  update public.order_issue_payments
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and expires_at <= now();

  update public.order_issue_payments
  set status = 'منتهي'
  where order_id = found_order.id
    and status = 'بانتظار الدفع';

  if p_currency = 'USD' then
    nominal_amount := round(greatest(coalesce(p_amount_usd, 0), coalesce(found_order.extra_amount_usd, 0)), 2);
    unit_step := 0.01;
  else
    select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
    usd_rate := coalesce(usd_rate, 13000);
    nominal_amount := round(greatest(coalesce(p_amount_usd, 0), coalesce(found_order.extra_amount_usd, 0)) * usd_rate);
    unit_step := 1;
  end if;

  for attempt in 0..max_attempts loop
    candidate_amount := nominal_amount - (attempt * unit_step);
    if candidate_amount <= 0 then
      exit;
    end if;

    if exists (
      select 1
      from public.orders
      where payment_status = 'بانتظار الدفع'
        and payment_currency = p_currency
        and payment_amount = candidate_amount
        and (payment_expires_at is null or payment_expires_at > now())
    ) then
      continue;
    end if;

    if exists (
      select 1
      from public.wallet_topups
      where status = 'بانتظار الدفع'
        and payment_currency = p_currency
        and payment_amount = candidate_amount
        and expires_at > now()
    ) then
      continue;
    end if;

    begin
      insert into public.order_issue_payments (
        order_id, requested_amount_usd, payment_amount, payment_currency, status, expires_at
      )
      values (
        found_order.id,
        greatest(coalesce(p_amount_usd, 0), coalesce(found_order.extra_amount_usd, 0)),
        candidate_amount,
        p_currency,
        'بانتظار الدفع',
        expires
      )
      returning id into new_payment_id;

      return jsonb_build_object(
        'issuePaymentId', new_payment_id,
        'orderId', found_order.id,
        'paymentAmount', candidate_amount,
        'paymentCurrency', p_currency,
        'paymentExpiresAt', expires
      );
    exception when unique_violation then
      continue;
    end;
  end loop;

  raise exception 'تعذر إيجاد مبلغ دفع فريد حالياً، حاول بعد دقيقة';
end;
$$;

revoke all on function public.create_order_issue_payment(text, numeric, text) from public;
grant execute on function public.create_order_issue_payment(text, numeric, text) to anon, authenticated;

create or replace function public.confirm_shamcash_payment_by_amount(
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
  order_count integer;
  topup_count integer;
  issue_count integer;
  matched_issue public.order_issue_payments%rowtype;
begin
  update public.wallet_topups
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and expires_at <= now();

  update public.order_issue_payments
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and expires_at <= now();

  select count(*) into order_count
  from public.orders
  where payment_status = 'بانتظار الدفع'
    and payment_currency = match_currency
    and payment_amount = match_amount
    and (payment_expires_at is null or payment_expires_at > now());

  select count(*) into topup_count
  from public.wallet_topups
  where status = 'بانتظار الدفع'
    and payment_currency = match_currency
    and payment_amount = match_amount
    and expires_at > now();

  select count(*) into issue_count
  from public.order_issue_payments
  where status = 'بانتظار الدفع'
    and payment_currency = match_currency
    and payment_amount = match_amount
    and expires_at > now();

  if order_count + topup_count + issue_count = 0 then
    return jsonb_build_object('matched', false, 'reason', 'not_found');
  end if;

  if order_count + topup_count + issue_count > 1 then
    return jsonb_build_object('matched', false, 'reason', 'ambiguous');
  end if;

  if issue_count = 1 then
    select * into matched_issue
    from public.order_issue_payments
    where status = 'بانتظار الدفع'
      and payment_currency = match_currency
      and payment_amount = match_amount
      and expires_at > now()
    limit 1;

    update public.order_issue_payments
    set status = 'مدفوع',
        paid_at = now(),
        notification_text = left(coalesce(confirm_shamcash_payment_by_amount.notification_text, ''), 1200)
    where id = matched_issue.id;

    update public.orders
    set payment_issue = false,
        payment_issue_note = '',
        extra_amount_usd = 0
    where id = matched_issue.order_id;

    insert into public.order_events (order_id, status_index, title, note)
    select matched_issue.order_id, status_index, 'تم حل مشكلة الدفع', 'تمت مطابقة الدفعة الإضافية عبر شام كاش'
    from public.orders
    where id = matched_issue.order_id;

    return jsonb_build_object(
      'matched', true,
      'type', 'order_issue_payment',
      'orderId', matched_issue.order_id,
      'issuePaymentId', matched_issue.id
    );
  end if;

  if topup_count = 1 then
    return public.confirm_wallet_topup_by_amount(match_amount, match_currency, notification_text);
  end if;

  return public.confirm_payment_by_amount(match_amount, match_currency, notification_text)
    || jsonb_build_object('type', 'order_payment');
end;
$$;

revoke all on function public.confirm_shamcash_payment_by_amount(numeric, text, text) from public;
grant execute on function public.confirm_shamcash_payment_by_amount(numeric, text, text) to service_role;
