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
alter table public.customers add column if not exists pickup_label text not null default '';
alter table public.customers add column if not exists notification_prefs jsonb not null default '{}'::jsonb;

create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  phone text not null,
  order_id text references public.orders(id) on delete set null,
  amount_syp integer not null check (amount_syp <> 0),
  amount_usd numeric(14, 2) not null default 0,
  kind text not null default 'manual_adjustment' check (kind in ('manual_adjustment', 'order_refund', 'order_payment', 'bonus', 'correction', 'wallet_topup')),
  note text not null default '',
  created_by text not null default 'system',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.wallet_transactions add column if not exists customer_id uuid references public.customers(id) on delete cascade;
alter table public.wallet_transactions add column if not exists phone text not null default '';
alter table public.wallet_transactions add column if not exists order_id text references public.orders(id) on delete set null;
alter table public.wallet_transactions add column if not exists amount_syp integer not null default 0;
alter table public.wallet_transactions add column if not exists amount_usd numeric(14, 2) not null default 0;
alter table public.wallet_transactions add column if not exists kind text not null default 'manual_adjustment';
alter table public.wallet_transactions add column if not exists note text not null default '';
alter table public.wallet_transactions add column if not exists created_by text not null default 'system';
alter table public.wallet_transactions add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.wallet_transactions add column if not exists created_at timestamptz not null default now();
update public.wallet_transactions set amount_usd = 0 where amount_usd is null;
alter table public.wallet_transactions alter column amount_usd set default 0;
alter table public.wallet_transactions alter column amount_usd set not null;

do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conrelid = 'public.wallet_transactions'::regclass
      and conname = 'wallet_transactions_kind_check'
  ) then
    alter table public.wallet_transactions drop constraint wallet_transactions_kind_check;
  end if;
end $$;

alter table public.wallet_transactions
  add constraint wallet_transactions_kind_check
  check (kind in ('manual_adjustment', 'order_refund', 'order_payment', 'bonus', 'correction', 'wallet_topup'));

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

create or replace function public.validate_customer_full_name(p_name text)
returns text
language plpgsql
immutable
as $$
declare
  normalized text := regexp_replace(trim(coalesce(p_name, '')), '\s+', ' ', 'g');
begin
  if normalized = '' then
    raise exception 'يرجى إدخال الاسم الكامل باستخدام كلمتين على الأقل.';
  end if;

  if array_length(regexp_split_to_array(normalized, '\s+'), 1) < 2 then
    raise exception 'يرجى إدخال الاسم الكامل باستخدام كلمتين على الأقل.';
  end if;

  if normalized ~ '[0-9٠-٩۰-۹]' then
    raise exception 'يرجى إدخال الاسم الكامل باستخدام كلمتين على الأقل.';
  end if;

  if normalized !~ ('^[A-Za-zء-يآأإؤئ' || chr(39) || '\- ]+$') then
    raise exception 'يرجى إدخال الاسم الكامل باستخدام كلمتين على الأقل.';
  end if;

  return normalized;
end;
$$;

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

insert into public.app_settings (key, value)
values
  ('shipping_cost_shein_syp', '90000'),
  ('shipping_cost_temu_syp', '90000'),
  ('shamcash_qr_shein_data_url', ''),
  ('shamcash_qr_temu_data_url', ''),
  ('shamcash_code_shein', ''),
  ('shamcash_code_temu', ''),
  ('referral_discount_syp', '0'),
  ('product_profit_percent', '0'),
  ('admin_session_version', '1')
on conflict (key) do nothing;

alter table public.orders add column if not exists payment_amount numeric(14, 2);
alter table public.orders add column if not exists payment_currency text not null default 'SYP' check (payment_currency in ('SYP', 'USD'));
alter table public.orders add column if not exists payment_expires_at timestamptz;
alter table public.orders add column if not exists payment_matched_by text not null default '';

create table if not exists public.wallet_topups (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  phone text not null,
  requested_amount_syp integer not null check (requested_amount_syp > 0),
  payment_amount numeric(14, 2) not null check (payment_amount > 0),
  payment_currency text not null default 'SYP' check (payment_currency in ('SYP', 'USD')),
  status text not null default 'بانتظار الدفع' check (status in ('بانتظار الدفع', 'مدفوع', 'منتهي', 'فشل المطابقة')),
  provider text not null default 'Sham Cash B2B',
  notification_text text not null default '',
  paid_at timestamptz,
  expires_at timestamptz not null default now() + interval '2 hours',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.wallet_topups add column if not exists customer_id uuid references public.customers(id) on delete cascade;
alter table public.wallet_topups add column if not exists phone text not null default '';
alter table public.wallet_topups add column if not exists requested_amount_syp integer not null default 0;
alter table public.wallet_topups add column if not exists payment_amount numeric(14, 2) not null default 0;
alter table public.wallet_topups add column if not exists payment_currency text not null default 'SYP';
alter table public.wallet_topups add column if not exists status text not null default 'بانتظار الدفع';
alter table public.wallet_topups add column if not exists provider text not null default 'Sham Cash B2B';
alter table public.wallet_topups add column if not exists notification_text text not null default '';
alter table public.wallet_topups add column if not exists paid_at timestamptz;
alter table public.wallet_topups add column if not exists expires_at timestamptz not null default now() + interval '2 hours';
alter table public.wallet_topups add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.wallet_topups add column if not exists created_at timestamptz not null default now();

create unique index if not exists wallet_topups_pending_payment_amount_uidx
  on public.wallet_topups (payment_currency, payment_amount)
  where status = 'بانتظار الدفع';

create index if not exists wallet_topups_customer_id_idx on public.wallet_topups (customer_id, created_at desc);
create index if not exists wallet_topups_phone_idx on public.wallet_topups (phone, created_at desc);
create index if not exists wallet_topups_status_idx on public.wallet_topups (status, expires_at);

alter table public.wallet_topups enable row level security;

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

alter table public.order_issue_payments add column if not exists order_id text not null default '';
alter table public.order_issue_payments add column if not exists payment_amount numeric(14, 2) not null default 0;
alter table public.order_issue_payments add column if not exists payment_currency text not null default 'SYP';
alter table public.order_issue_payments add column if not exists requested_amount_usd numeric(14, 2) not null default 0;
alter table public.order_issue_payments add column if not exists status text not null default 'بانتظار الدفع';
alter table public.order_issue_payments add column if not exists notification_text text not null default '';
alter table public.order_issue_payments add column if not exists paid_at timestamptz;
alter table public.order_issue_payments add column if not exists expires_at timestamptz not null default now() + interval '5 minutes';
alter table public.order_issue_payments add column if not exists created_at timestamptz not null default now();

create unique index if not exists order_issue_payments_pending_amount_uidx
  on public.order_issue_payments (payment_currency, payment_amount)
  where status = 'بانتظار الدفع';

create index if not exists order_issue_payments_order_id_idx on public.order_issue_payments (order_id, created_at desc);
create index if not exists order_issue_payments_status_idx on public.order_issue_payments (status, expires_at);

alter table public.order_issue_payments enable row level security;

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

create or replace function public.create_wallet_topup(
  p_phone text,
  p_name text default '',
  p_amount_syp integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  cleaned_phone text := regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g');
  requested_amount integer := greatest(coalesce(p_amount_syp, 0), 0);
  target_customer_id uuid;
  candidate_amount numeric;
  expires timestamptz := now() + interval '2 hours';
  attempt integer;
  max_attempts integer := 40;
  inserted_topup_id uuid;
begin
  if cleaned_phone = '' then
    raise exception 'phone is required';
  end if;

  if requested_amount <= 0 then
    raise exception 'amount is required';
  end if;

  target_customer_id := public.ensure_customer(
    cleaned_phone,
    coalesce(nullif(trim(coalesce(p_name, '')), ''), 'عميل طلبية'),
    'دمشق',
    '',
    '',
    ''
  );

  update public.wallet_topups
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and expires_at <= now();

  for attempt in 0..max_attempts loop
    candidate_amount := requested_amount - attempt;
    if candidate_amount <= 0 then
      exit;
    end if;

    if exists (
      select 1
      from public.orders
      where payment_status = 'بانتظار الدفع'
        and payment_currency = 'SYP'
        and payment_amount = candidate_amount
        and (payment_expires_at is null or payment_expires_at > now())
    ) then
      continue;
    end if;

    if exists (
      select 1
      from public.order_issue_payments
      where status = 'ط¨ط§ظ†طھط¸ط§ط± ط§ظ„ط¯ظپط¹'
        and payment_currency = 'SYP'
        and payment_amount = candidate_amount
        and expires_at > now()
    ) then
      continue;
    end if;

    begin
      insert into public.wallet_topups (
        customer_id, phone, requested_amount_syp, payment_amount,
        payment_currency, status, expires_at
      )
      values (
        target_customer_id, cleaned_phone, requested_amount, candidate_amount,
        'SYP', 'بانتظار الدفع', expires
      )
      returning id into inserted_topup_id;

      return jsonb_build_object(
        'topUpId', inserted_topup_id,
        'paymentAmount', candidate_amount,
        'paymentCurrency', 'SYP',
        'paymentExpiresAt', expires,
        'creditAmountSyp', candidate_amount::integer
      );
    exception when unique_violation then
      continue;
    end;
  end loop;

  raise exception 'تعذر إيجاد مبلغ شحن فريد حالياً، حاول بعد دقيقة';
end;
$$;

revoke all on function public.create_wallet_topup(text, text, integer) from public;
grant execute on function public.create_wallet_topup(text, text, integer) to anon, authenticated;

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
  update public.wallet_topups
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and expires_at <= now();

  select count(*) into match_count
  from public.wallet_topups
  where status = 'بانتظار الدفع'
    and payment_currency = match_currency
    and payment_amount = match_amount
    and expires_at > now();

  if match_count = 0 then
    return jsonb_build_object('matched', false, 'reason', 'not_found');
  end if;

  if match_count > 1 then
    return jsonb_build_object('matched', false, 'reason', 'ambiguous');
  end if;

  select * into matched_topup
  from public.wallet_topups
  where status = 'بانتظار الدفع'
    and payment_currency = match_currency
    and payment_amount = match_amount
    and expires_at > now()
  limit 1
  for update;

  credit_amount := greatest(round(matched_topup.payment_amount)::integer, 0);

  update public.wallet_topups
  set status = 'مدفوع',
      paid_at = now(),
      notification_text = left(coalesce(raw_notification_text, ''), 1200)
  where id = matched_topup.id;

  insert into public.wallet_transactions (
    customer_id, phone, amount_syp, amount_usd, kind, note, created_by, metadata
  )
  values (
    matched_topup.customer_id,
    matched_topup.phone,
    credit_amount,
    0,
    'wallet_topup',
    'شحن محفظة عبر شام كاش',
    'sham-cash-webhook',
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
    'matched', true,
    'type', 'wallet_topup',
    'topUpId', matched_topup.id,
    'phone', matched_topup.phone,
    'creditAmountSyp', credit_amount,
    'walletBalanceSyp', wallet_balance
  );
end;
$$;

revoke all on function public.confirm_wallet_topup_by_amount(numeric, text, text) from public;
grant execute on function public.confirm_wallet_topup_by_amount(numeric, text, text) to service_role;

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

create or replace function public.get_wallet_topup_status(target_topup_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  found_topup public.wallet_topups%rowtype;
  wallet_balance integer := 0;
  credit_amount integer := 0;
begin
  update public.wallet_topups
  set status = 'منتهي'
  where id = nullif(target_topup_id, '')::uuid
    and status = 'بانتظار الدفع'
    and expires_at <= now();

  select * into found_topup
  from public.wallet_topups
  where id = nullif(target_topup_id, '')::uuid;

  if not found then
    return jsonb_build_object('found', false);
  end if;

  credit_amount := greatest(round(found_topup.payment_amount)::integer, 0);

  select coalesce(sum(amount_syp), 0)::integer into wallet_balance
  from public.wallet_transactions
  where customer_id = found_topup.customer_id;

  return jsonb_build_object(
    'found', true,
    'status', found_topup.status,
    'paidAt', found_topup.paid_at,
    'paymentAmount', found_topup.payment_amount,
    'paymentCurrency', found_topup.payment_currency,
    'paymentExpiresAt', found_topup.expires_at,
    'creditAmountSyp', credit_amount,
    'walletBalanceSyp', wallet_balance
  );
end;
$$;

revoke all on function public.get_wallet_topup_status(text) from public;
grant execute on function public.get_wallet_topup_status(text) to anon, authenticated;

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
-- أكواد الخصم
-- ============================================================================

create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  kind text not null check (kind in ('percent', 'fixed')),
  value numeric(14, 2) not null check (value > 0),
  applies_to text not null default 'all' check (applies_to in ('all', 'shein', 'temu')),
  active boolean not null default true,
  max_uses integer,
  used_count integer not null default 0,
  min_subtotal_syp integer not null default 0,
  starts_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.coupon_redemptions (
  id uuid primary key default gen_random_uuid(),
  coupon_id uuid not null references public.coupons(id) on delete cascade,
  phone text not null,
  device_id text not null default '',
  order_id text,
  discount_syp integer not null default 0,
  created_at timestamptz not null default now()
);

create unique index if not exists coupon_redemptions_phone_uidx
  on public.coupon_redemptions (coupon_id, phone);

create unique index if not exists coupon_redemptions_device_uidx
  on public.coupon_redemptions (coupon_id, device_id)
  where device_id <> '';

alter table public.coupons enable row level security;
alter table public.coupon_redemptions enable row level security;

create or replace function public.redeem_coupon(
  p_code text,
  p_phone text,
  p_device_id text,
  p_store text,
  p_subtotal_syp integer,
  p_usd_rate numeric default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  found_coupon public.coupons%rowtype;
  rate numeric;
  discount_syp integer := 0;
begin
  if coalesce(nullif(trim(p_phone), ''), '') = '' then
    return jsonb_build_object('valid', false, 'reason', 'no_phone');
  end if;

  select *
    into found_coupon
    from public.coupons
   where lower(code) = lower(trim(p_code))
   limit 1;

  if not found then
    return jsonb_build_object('valid', false, 'reason', 'not_found');
  end if;
  if not found_coupon.active then
    return jsonb_build_object('valid', false, 'reason', 'inactive');
  end if;
  if found_coupon.starts_at is not null and found_coupon.starts_at > now() then
    return jsonb_build_object('valid', false, 'reason', 'not_started');
  end if;
  if found_coupon.expires_at is not null and found_coupon.expires_at < now() then
    return jsonb_build_object('valid', false, 'reason', 'expired');
  end if;
  if found_coupon.applies_to <> 'all' and found_coupon.applies_to <> lower(coalesce(p_store, '')) then
    return jsonb_build_object('valid', false, 'reason', 'wrong_store');
  end if;
  if coalesce(p_subtotal_syp, 0) < found_coupon.min_subtotal_syp then
    return jsonb_build_object('valid', false, 'reason', 'below_min');
  end if;
  if found_coupon.max_uses is not null and found_coupon.used_count >= found_coupon.max_uses then
    return jsonb_build_object('valid', false, 'reason', 'exhausted');
  end if;

  if found_coupon.kind = 'percent' then
    discount_syp := floor(coalesce(p_subtotal_syp, 0) * least(greatest(found_coupon.value, 0), 100) / 100.0);
  else
    select value::numeric
      into rate
      from public.app_settings
     where key = 'usd_to_syp_rate';
    rate := coalesce(p_usd_rate, rate, 13000);
    discount_syp := floor(found_coupon.value * rate);
  end if;

  if discount_syp < 0 then
    discount_syp := 0;
  end if;
  if discount_syp > coalesce(p_subtotal_syp, 0) then
    discount_syp := coalesce(p_subtotal_syp, 0);
  end if;

  begin
    insert into public.coupon_redemptions (coupon_id, phone, device_id, discount_syp)
    values (
      found_coupon.id,
      trim(p_phone),
      coalesce(nullif(trim(p_device_id), ''), ''),
      discount_syp
    );
  exception when unique_violation then
    return jsonb_build_object('valid', false, 'reason', 'already_used');
  end;

  update public.coupons
     set used_count = used_count + 1
   where id = found_coupon.id;

  return jsonb_build_object(
    'valid', true,
    'discountSyp', discount_syp,
    'code', found_coupon.code,
    'kind', found_coupon.kind
  );
end;
$$;

revoke all on function public.redeem_coupon(text, text, text, text, integer, numeric) from public;
grant execute on function public.redeem_coupon(text, text, text, text, integer, numeric) to anon, authenticated;

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

create or replace function public.update_customer_preferences(
  p_phone text,
  p_pickup_label text default '',
  p_notification_prefs jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  cleaned_phone text := regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g');
  normalized_prefs jsonb := case
    when jsonb_typeof(coalesce(p_notification_prefs, '{}'::jsonb)) = 'object' then coalesce(p_notification_prefs, '{}'::jsonb)
    else '{}'::jsonb
  end;
begin
  if cleaned_phone = '' then
    raise exception 'phone is required';
  end if;

  insert into public.customers (phone)
  values (cleaned_phone)
  on conflict (phone) do nothing;

  update public.customers
  set
    pickup_label = trim(coalesce(p_pickup_label, '')),
    notification_prefs = normalized_prefs,
    updated_at = now()
  where phone = cleaned_phone;

  return public.get_customer_account(cleaned_phone);
end;
$$;

revoke all on function public.update_customer_preferences(text, text, jsonb) from public;
grant execute on function public.update_customer_preferences(text, text, jsonb) to anon, authenticated;

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
    generated_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 7));
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

  if found_group.host_customer_id = customer_id then
    raise exception 'same customer cannot join own group';
  end if;

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
