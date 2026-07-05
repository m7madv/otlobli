create extension if not exists pgcrypto;

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  phone text not null unique,
  name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.customers(id) on delete cascade,
  label text not null default 'عنوان',
  name text not null,
  phone text not null,
  governorate text not null,
  city text not null,
  details text not null,
  notes text not null default '',
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.catalog_products (
  id uuid primary key default gen_random_uuid(),
  external_id text not null unique,
  source text not null default 'manual',
  source_link text,
  payload jsonb not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id text primary key,
  customer_id uuid references public.customers(id) on delete set null,
  customer_name text not null,
  phone text not null,
  city text not null,
  address text not null,
  total_syp integer not null check (total_syp >= 0),
  payment_status text not null check (payment_status in ('بانتظار الدفع', 'مدفوع', 'فشل المطابقة')),
  status_index integer not null default 0 check (status_index >= 0),
  qadmous_number text not null default '',
  created_at date not null default current_date,
  paid_at date,
  payment_issue boolean not null default false,
  payment_issue_note text not null default '',
  extra_amount_usd numeric(14,2) not null default 0
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id text not null references public.orders(id) on delete cascade,
  product_id text not null,
  title text not null,
  image text not null,
  color text not null,
  size text not null,
  quantity integer not null check (quantity > 0),
  price_syp integer not null check (price_syp >= 0),
  source_link text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.payment_verifications (
  id uuid primary key default gen_random_uuid(),
  order_id text references public.orders(id) on delete set null,
  provider text not null default 'Sham Cash B2B',
  amount_syp integer not null check (amount_syp > 0),
  status text not null check (status in ('matched', 'pending', 'failed')),
  match_rule text not null default 'exact_amount',
  raw_result jsonb not null default '{}'::jsonb,
  matched_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.otp_challenges (
  id uuid primary key default gen_random_uuid(),
  phone text not null,
  channel text not null default 'whatsapp',
  provider text not null default 'whatsapp_cloud_api',
  status text not null default 'pending' check (status in ('pending', 'sent', 'verified', 'expired', 'failed')),
  code_hash text not null,
  attempts integer not null default 0 check (attempts >= 0),
  expires_at timestamptz not null,
  sent_at timestamptz,
  verified_at timestamptz,
  provider_message_id text,
  provider_response jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.order_events (
  id uuid primary key default gen_random_uuid(),
  order_id text not null references public.orders(id) on delete cascade,
  status_index integer not null check (status_index >= 0),
  title text not null,
  note text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists orders_created_at_idx on public.orders (created_at desc);
create index if not exists orders_payment_status_idx on public.orders (payment_status);
create index if not exists orders_status_index_idx on public.orders (status_index);
create index if not exists order_items_order_id_idx on public.order_items (order_id);
create index if not exists order_events_order_id_idx on public.order_events (order_id);
create index if not exists otp_challenges_phone_created_at_idx on public.otp_challenges (phone, created_at desc);
create index if not exists otp_challenges_expires_at_idx on public.otp_challenges (expires_at);

alter table public.customers add column if not exists governorate text not null default 'دمشق';
alter table public.customers add column if not exists city text not null default '';
alter table public.customers add column if not exists qadmous_branch text not null default '';
alter table public.customers add column if not exists details text not null default '';

create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  phone text not null,
  order_id text references public.orders(id) on delete set null,
  amount_syp integer not null check (amount_syp <> 0),
  kind text not null default 'manual_adjustment' check (kind in ('manual_adjustment', 'order_refund', 'order_payment', 'bonus', 'correction')),
  note text not null default '',
  created_by text not null default 'system',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.cart_groups (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  host_customer_id uuid not null references public.customers(id) on delete cascade,
  payer_customer_id uuid references public.customers(id) on delete set null,
  status text not null default 'open' check (status in ('open', 'locked', 'ordered', 'cancelled')),
  source_store text not null default 'shein',
  min_total_usd numeric(14, 2) not null default 40,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '48 hours'
);

create table if not exists public.cart_group_members (
  group_id uuid not null references public.cart_groups(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  phone text not null,
  display_name text not null default '',
  role text not null default 'member' check (role in ('host', 'member')),
  joined_at timestamptz not null default now(),
  primary key (group_id, customer_id)
);

create table if not exists public.cart_group_items (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.cart_groups(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  local_item_id text not null,
  payload jsonb not null,
  price_usd numeric(14, 2) not null default 0,
  price_syp integer not null default 0,
  quantity integer not null default 1 check (quantity > 0),
  updated_at timestamptz not null default now(),
  unique (group_id, customer_id, local_item_id)
);

alter table public.orders add column if not exists group_id uuid references public.cart_groups(id) on delete set null;
alter table public.orders add column if not exists group_code text not null default '';

create index if not exists customers_phone_idx on public.customers (phone);
create index if not exists orders_customer_id_idx on public.orders (customer_id);
create index if not exists orders_group_id_idx on public.orders (group_id);
create index if not exists wallet_transactions_customer_id_idx on public.wallet_transactions (customer_id, created_at desc);
create index if not exists wallet_transactions_phone_idx on public.wallet_transactions (phone);
create index if not exists cart_groups_code_idx on public.cart_groups (code);
create index if not exists cart_group_items_group_id_idx on public.cart_group_items (group_id);

alter table public.customers enable row level security;
alter table public.addresses enable row level security;
alter table public.catalog_products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.payment_verifications enable row level security;
alter table public.otp_challenges enable row level security;
alter table public.order_events enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.cart_groups enable row level security;
alter table public.cart_group_members enable row level security;
alter table public.cart_group_items enable row level security;

drop policy if exists "Public can read active catalog products" on public.catalog_products;
create policy "Public can read active catalog products"
on public.catalog_products
for select
using (is_active = true);

drop policy if exists "Public can insert payment verification attempts" on public.payment_verifications;
create policy "Public can insert payment verification attempts"
on public.payment_verifications
for insert
with check (true);

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
  target_id uuid;
begin
  if cleaned_phone = '' then
    raise exception 'phone is required';
  end if;

  insert into public.customers (phone, name, governorate, qadmous_branch, city, details)
  values (
    cleaned_phone,
    nullif(trim(coalesce(p_name, '')), ''),
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

create or replace function public.upsert_customer_from_order(order_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
begin
  return public.ensure_customer(
    coalesce(nullif(order_payload->>'phone', ''), 'غير محدد'),
    coalesce(nullif(order_payload->>'customer', ''), 'عميل otlobli'),
    coalesce(nullif(order_payload->>'governorate', ''), nullif(order_payload->>'city', ''), 'دمشق'),
    coalesce(order_payload->>'qadmousBranch', ''),
    coalesce(order_payload->>'city', ''),
    coalesce(order_payload->>'address', '')
  );
end;
$$;

revoke all on function public.upsert_customer_from_order(jsonb) from public;
grant execute on function public.upsert_customer_from_order(jsonb) to anon, authenticated, service_role;

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
    source_link
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
    item."sourceLink"
  from jsonb_to_recordset(order_payload->'items') as item(
    id text,
    title text,
    image text,
    color text,
    size text,
    quantity integer,
    "priceSyp" integer,
    "sourceLink" text
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

insert into public.catalog_products (external_id, source, source_link, payload, is_active)
values (
  'SHEIN-DRS-204',
  'manual-demo',
  'https://jo.shein.com/example-product-p-12345.html',
  '{
    "id": "SHEIN-DRS-204",
    "title": "فستان بوهيمي مزين بالزهور",
    "source": "متجر خارجي",
    "link": "https://jo.shein.com/example-product-p-12345.html",
    "priceUsd": 25,
    "priceSyp": 325000,
    "weight": "0.62 كغ",
    "deliveryWindow": "10 إلى 15 يوم عمل",
    "images": [
      "https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?auto=format&fit=crop&w=900&q=84",
      "https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=900&q=84",
      "https://images.unsplash.com/photo-1539008835657-9e8e9680c956?auto=format&fit=crop&w=900&q=84"
    ],
    "colors": [
      {
        "name": "نقشة زهور ربيعية",
        "image": "https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=200&q=72"
      },
      {
        "name": "أزرق هادئ",
        "image": "https://images.unsplash.com/photo-1485968579580-b6d095142e6e?auto=format&fit=crop&w=200&q=72"
      },
      {
        "name": "كريمي",
        "image": "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=200&q=72"
      }
    ],
    "sizes": ["S", "M", "L", "XL"]
  }'::jsonb,
  true
)
on conflict (external_id) do update set
  source = excluded.source,
  source_link = excluded.source_link,
  payload = excluded.payload,
  is_active = excluded.is_active,
  updated_at = now();

-- ============================================================================
-- Real Sham Cash payment confirmation (replaces the client-side mock matcher)
--
-- Same mechanism as the "مكثفات بيان" project: every pending order gets a
-- unique payment_amount (nudged down by tiny steps from the nominal total
-- only on the rare collision with another currently-pending order), and a
-- phone running MacroDroid on the merchant's Sham Cash account forwards the
-- payment notification text to a webhook, which matches it to an order by
-- that exact amount and confirms it automatically.
-- ============================================================================

create table if not exists public.app_settings (
  key text primary key,
  value text not null
);

insert into public.app_settings (key, value)
values ('usd_to_syp_rate', '13000')
on conflict (key) do nothing;

alter table public.orders add column if not exists payment_amount numeric(14, 2);
alter table public.orders add column if not exists payment_currency text not null default 'SYP' check (payment_currency in ('SYP', 'USD'));
alter table public.orders add column if not exists payment_expires_at timestamptz;
alter table public.orders add column if not exists payment_matched_by text not null default '';

-- Guarantees no two currently-pending orders can ever be assigned the same
-- (currency, amount) pair, even under concurrent checkout requests.
create unique index if not exists orders_pending_payment_amount_uidx
  on public.orders (payment_currency, payment_amount)
  where payment_status = 'بانتظار الدفع';

alter table public.app_settings enable row level security;

-- Creates the order in "بانتظار الدفع" status and assigns it a unique payment
-- amount. The SYP/USD conversion rate is read from app_settings (server-side
-- truth) rather than trusted from the client, since the client's exchange
-- rate is just a display preference and must never affect how much money is
-- actually owed.
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

  for attempt in 0..max_attempts loop
    candidate_amount := nominal_amount - (attempt * unit_step);
    if candidate_amount <= 0 then
      exit;
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
        order_id, product_id, title, image, color, size, quantity, price_syp, source_link
      )
      select
        target_order_id, item.id, item.title, item.image, item.color, item.size,
        greatest(coalesce(item.quantity, 1), 1), greatest(coalesce(item."priceSyp", 0), 0), item."sourceLink"
      from jsonb_to_recordset(order_payload->'items') as item(
        id text, title text, image text, color text, size text,
        quantity integer, "priceSyp" integer, "sourceLink" text
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

-- Called only by the payment-webhook Edge Function (service role), never
-- exposed to the app directly - that's what makes "confirmed automatically
-- by a real transfer" trustworthy instead of just another client claim.
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

  if match_count = 0 then
    return jsonb_build_object('matched', false, 'reason', 'not_found');
  end if;

  if match_count > 1 then
    return jsonb_build_object('matched', false, 'reason', 'ambiguous');
  end if;

  select * into matched_order
  from public.orders
  where payment_status = 'بانتظار الدفع'
    and payment_currency = match_currency
    and payment_amount = match_amount
    and (payment_expires_at is null or payment_expires_at > now())
  limit 1
  for update;

  update public.orders
  set payment_status = 'مدفوع',
      status_index = 1,
      paid_at = current_date,
      payment_matched_by = 'sham-cash-webhook'
  where id = matched_order.id;

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

revoke all on function public.confirm_payment_by_amount(numeric, text, text) from public;
grant execute on function public.confirm_payment_by_amount(numeric, text, text) to service_role;

-- Narrow, anon-callable status lookup so the app can poll "did the transfer
-- arrive yet?" without needing a general SELECT policy on public.orders.
create or replace function public.get_order_payment_status(target_order_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  found_order public.orders%rowtype;
begin
  select * into found_order from public.orders where id = target_order_id;
  if not found then
    return jsonb_build_object('found', false);
  end if;

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

revoke all on function public.get_order_payment_status(text) from public;
grant execute on function public.get_order_payment_status(text) to anon, authenticated;

-- ============================================================================
-- بوابة السواق — تكليف طلبات لسواق معيّن يستلمها من مندوب شيين بلبنان،
-- يفرزها ويغلفها لكل زبون، ويشحنها على سوريا عبر القدموس.
-- ============================================================================

create table if not exists public.drivers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  login_code text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.orders add column if not exists assigned_driver_id uuid references public.drivers(id) on delete set null;
alter table public.orders add column if not exists assigned_at timestamptz;

create index if not exists orders_assigned_driver_id_idx on public.orders (assigned_driver_id);

alter table public.drivers enable row level security;
-- بدون policies عامة — الوصول فقط عبر Edge Functions بصلاحية service role

-- ============================================================================
-- خصم الإحالة — كود الإحالة هو رقم هاتف عميل سابق نفسه (بلا جدول/توليد
-- إضافي)؛ هاي الدالة فقط تتحقق إنه رقم حقيقي لعميل عنده طلب سابق قبل ما
-- التطبيق يطبّق خصم الإحالة على طلب العميل الجديد.
-- ============================================================================

create or replace function public.check_referral_code(ref_phone text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists(select 1 from public.orders where phone = ref_phone);
$$;

revoke all on function public.check_referral_code(text) from public;
grant execute on function public.check_referral_code(text) to anon, authenticated;

-- ============================================================================
-- تقييم ما بعد التسليم — نجوم (1-5) + ملاحظة اختيارية، مرة واحدة لكل طلب.
-- ============================================================================

alter table public.orders add column if not exists rating integer check (rating between 1 and 5);
alter table public.orders add column if not exists rating_note text not null default '';
alter table public.orders add column if not exists rated_at timestamptz;

create or replace function public.submit_order_rating(target_order_id text, p_stars integer, p_note text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  if p_stars < 1 or p_stars > 5 then
    return false;
  end if;

  update public.orders
  set rating = p_stars,
      rating_note = coalesce(p_note, ''),
      rated_at = now()
  where id = target_order_id
    and rating is null;

  get diagnostics updated_count = row_count;
  return updated_count > 0;
end;
$$;

revoke all on function public.submit_order_rating(text, integer, text) from public;
grant execute on function public.submit_order_rating(text, integer, text) to anon, authenticated;

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
          'sourceLink', oi.source_link
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
      'details', coalesce(found_customer.details, ''),
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

create or replace function public.upsert_customer_profile(
  p_phone text,
  p_name text,
  p_governorate text,
  p_qadmous_branch text default '',
  p_city text default '',
  p_details text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  customer_id uuid;
begin
  customer_id := public.ensure_customer(p_phone, p_name, p_governorate, p_qadmous_branch, p_city, p_details);
  return public.get_customer_account((select phone from public.customers where id = customer_id));
end;
$$;

revoke all on function public.upsert_customer_profile(text, text, text, text, text, text) from public;
grant execute on function public.upsert_customer_profile(text, text, text, text, text, text) to anon, authenticated;

create or replace function public.replace_cart_group_items(p_group_id uuid, p_customer_id uuid, p_items jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(jsonb_typeof(p_items), '') <> 'array' then
    p_items := '[]'::jsonb;
  end if;

  delete from public.cart_group_items
  where group_id = p_group_id and customer_id = p_customer_id;

  insert into public.cart_group_items (
    group_id, customer_id, local_item_id, payload, price_usd, price_syp, quantity
  )
  select
    p_group_id,
    p_customer_id,
    coalesce(nullif(item->>'id', ''), gen_random_uuid()::text),
    item,
    greatest(coalesce(nullif(item->>'priceUsd', '')::numeric, 0), 0),
    greatest(coalesce(nullif(item->>'priceSyp', '')::integer, 0), 0),
    greatest(coalesce(nullif(item->>'quantity', '')::integer, 1), 1)
  from jsonb_array_elements(p_items) as item;
end;
$$;

revoke all on function public.replace_cart_group_items(uuid, uuid, jsonb) from public;
grant execute on function public.replace_cart_group_items(uuid, uuid, jsonb) to anon, authenticated, service_role;

create or replace function public.cart_group_snapshot(p_group_id uuid)
returns jsonb
language sql
security definer
set search_path = public
stable
as $$
  select jsonb_build_object(
    'id', g.id,
    'code', g.code,
    'status', g.status,
    'minTotalUsd', g.min_total_usd,
    'totalUsd', coalesce((select sum(cgi.price_usd * cgi.quantity) from public.cart_group_items cgi where cgi.group_id = g.id), 0),
    'members', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'phone', cgm.phone,
        'name', cgm.display_name,
        'role', cgm.role
      ) order by cgm.joined_at), '[]'::jsonb)
      from public.cart_group_members cgm
      where cgm.group_id = g.id
    ),
    'items', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'ownerPhone', cgm.phone,
        'ownerName', cgm.display_name,
        'item', cgi.payload
      ) order by cgi.updated_at), '[]'::jsonb)
      from public.cart_group_items cgi
      join public.cart_group_members cgm
        on cgm.group_id = cgi.group_id and cgm.customer_id = cgi.customer_id
      where cgi.group_id = g.id
    )
  )
  from public.cart_groups g
  where g.id = p_group_id;
$$;

revoke all on function public.cart_group_snapshot(uuid) from public;
grant execute on function public.cart_group_snapshot(uuid) to anon, authenticated, service_role;

create or replace function public.create_cart_group(p_phone text, p_name text, p_store text, p_items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  customer_id uuid;
  group_id uuid;
  generated_code text;
  attempt integer;
begin
  customer_id := public.ensure_customer(p_phone, p_name, 'دمشق', '', '', '');

  for attempt in 1..12 loop
    generated_code := upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 6));
    begin
      insert into public.cart_groups (code, host_customer_id, source_store)
      values (generated_code, customer_id, coalesce(nullif(p_store, ''), 'shein'))
      returning id into group_id;
      exit;
    exception when unique_violation then
      continue;
    end;
  end loop;

  if group_id is null then
    raise exception 'could not generate group code';
  end if;

  insert into public.cart_group_members (group_id, customer_id, phone, display_name, role)
  values (group_id, customer_id, regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g'), coalesce(nullif(trim(p_name), ''), 'صاحب الطلب'), 'host')
  on conflict (group_id, customer_id) do update set
    display_name = excluded.display_name,
    role = 'host';

  perform public.replace_cart_group_items(group_id, customer_id, p_items);
  return public.cart_group_snapshot(group_id);
end;
$$;

revoke all on function public.create_cart_group(text, text, text, jsonb) from public;
grant execute on function public.create_cart_group(text, text, text, jsonb) to anon, authenticated;

create or replace function public.join_cart_group(p_phone text, p_name text, p_code text, p_items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  customer_id uuid;
  found_group public.cart_groups%rowtype;
begin
  select * into found_group
  from public.cart_groups
  where code = upper(trim(p_code))
    and status = 'open'
    and expires_at > now()
  limit 1;

  if not found then
    raise exception 'group not found';
  end if;

  customer_id := public.ensure_customer(p_phone, p_name, 'دمشق', '', '', '');

  insert into public.cart_group_members (group_id, customer_id, phone, display_name, role)
  values (found_group.id, customer_id, regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g'), coalesce(nullif(trim(p_name), ''), 'عضو'), 'member')
  on conflict (group_id, customer_id) do update set
    display_name = excluded.display_name;

  perform public.replace_cart_group_items(found_group.id, customer_id, p_items);
  return public.cart_group_snapshot(found_group.id);
end;
$$;

revoke all on function public.join_cart_group(text, text, text, jsonb) from public;
grant execute on function public.join_cart_group(text, text, text, jsonb) to anon, authenticated;

create or replace function public.sync_cart_group_items(p_phone text, p_group_id uuid, p_items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  customer_id uuid;
begin
  select c.id into customer_id
  from public.customers c
  join public.cart_group_members m on m.customer_id = c.id
  where c.phone = regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g')
    and m.group_id = p_group_id
  limit 1;

  if customer_id is null then
    raise exception 'not a group member';
  end if;

  perform public.replace_cart_group_items(p_group_id, customer_id, p_items);
  return public.cart_group_snapshot(p_group_id);
end;
$$;

revoke all on function public.sync_cart_group_items(text, uuid, jsonb) from public;
grant execute on function public.sync_cart_group_items(text, uuid, jsonb) to anon, authenticated;
