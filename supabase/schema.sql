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
  paid_at date
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

alter table public.customers enable row level security;
alter table public.addresses enable row level security;
alter table public.catalog_products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.payment_verifications enable row level security;
alter table public.otp_challenges enable row level security;
alter table public.order_events enable row level security;

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

  insert into public.orders (
    id,
    customer_name,
    phone,
    city,
    address,
    total_syp,
    payment_status,
    status_index,
    qadmous_number,
    created_at,
    paid_at
  )
  values (
    target_order_id,
    coalesce(nullif(order_payload->>'customer', ''), 'عميل طلبية'),
    coalesce(nullif(order_payload->>'phone', ''), 'غير محدد'),
    coalesce(nullif(order_payload->>'city', ''), 'غير محدد'),
    coalesce(nullif(order_payload->>'address', ''), 'عنوان غير مكتمل'),
    greatest(coalesce(nullif(order_payload->>'total', '')::integer, 0), 0),
    coalesce(nullif(order_payload->>'paymentStatus', ''), 'بانتظار الدفع'),
    target_status_index,
    coalesce(order_payload->>'qadmousNumber', ''),
    coalesce(nullif(order_payload->>'createdAt', '')::date, current_date),
    target_paid_at
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

  for attempt in 0..max_attempts loop
    candidate_amount := nominal_amount - (attempt * unit_step);
    if candidate_amount <= 0 then
      exit;
    end if;

    begin
      insert into public.orders (
        id, customer_name, phone, city, address, total_syp,
        payment_status, status_index, qadmous_number, created_at,
        payment_amount, payment_currency, payment_expires_at
      )
      values (
        target_order_id,
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
        expires
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
    'qadmousNumber', found_order.qadmous_number
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
