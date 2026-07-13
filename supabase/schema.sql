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
  extra_amount_usd numeric(14,2) not null default 0,
  -- فاتورة الطلب (v60): بنود رسوم يحررها المشرف من لوحة الإدارة
  -- (شحن سعودية→سوريا، رسوم منصة...) وتظهر للزبون في تفاصيل الطلب.
  -- الشكل: [{"label": "شحن", "amountUsd": 2}, ...]
  invoice jsonb not null default '[]'::jsonb,
  -- مشاكل الطلب المنظمة (v63): مصفوفة {id,type,itemId,note,requiredSize,
  -- options[],amountUsd,resolved,resolvedValue} — عدة مشاكل لكل طلب يحلها
  -- الزبون من طلباتي. مسار الدفع يبقى في payment_issue/extra_amount_usd.
  issues jsonb not null default '[]'::jsonb
);

alter table public.orders add column if not exists delivery_member_key text not null default '';
alter table public.orders add column if not exists delivery_owner_phone text not null default '';
alter table public.orders add column if not exists delivery_owner_name text not null default '';

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
  created_at timestamptz not null default now(),
  -- حقول المنتجات المخصصة (v59): نص النقش وصورة الزبون (data URL) وملاحظة
  -- قياس الصورة من صفحة المنتج — يرسلها التطبيق ويعرضها للوحة الإدارة.
  custom_text text not null default '',
  custom_photo text not null default '',
  custom_photo_note text not null default '',
  owner_member_key text not null default '',
  owner_phone text not null default '',
  owner_name text not null default ''
);

alter table public.order_items add column if not exists owner_member_key text not null default '';
alter table public.order_items add column if not exists owner_phone text not null default '';
alter table public.order_items add column if not exists owner_name text not null default '';

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
  member_key text not null default '',
  phone text not null,
  display_name text not null default '',
  role text not null default 'member' check (role in ('host', 'member')),
  joined_at timestamptz not null default now(),
  primary key (group_id, member_key)
);

create table if not exists public.cart_group_items (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.cart_groups(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  member_key text not null default '',
  local_item_id text not null,
  payload jsonb not null,
  price_usd numeric(14, 2) not null default 0,
  price_syp integer not null default 0,
  quantity integer not null default 1 check (quantity > 0),
  updated_at timestamptz not null default now(),
  unique (group_id, member_key, local_item_id)
);

alter table public.cart_group_members add column if not exists member_key text not null default '';
alter table public.cart_group_items add column if not exists member_key text not null default '';

update public.cart_group_members
set member_key = coalesce(nullif(member_key, ''), customer_id::text)
where member_key = '';

update public.cart_group_items
set member_key = coalesce(nullif(member_key, ''), customer_id::text)
where member_key = '';

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'cart_group_members_pkey'
      and conrelid = 'public.cart_group_members'::regclass
  ) then
    alter table public.cart_group_members drop constraint cart_group_members_pkey;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'cart_group_members_group_id_member_key_key'
      and conrelid = 'public.cart_group_members'::regclass
  ) then
    alter table public.cart_group_members
      add constraint cart_group_members_group_id_member_key_key unique (group_id, member_key);
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'cart_group_items_group_id_customer_id_local_item_id_key'
      and conrelid = 'public.cart_group_items'::regclass
  ) then
    alter table public.cart_group_items drop constraint cart_group_items_group_id_customer_id_local_item_id_key;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'cart_group_items_group_id_member_key_local_item_id_key'
      and conrelid = 'public.cart_group_items'::regclass
  ) then
    alter table public.cart_group_items
      add constraint cart_group_items_group_id_member_key_local_item_id_key unique (group_id, member_key, local_item_id);
  end if;
end $$;

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
    group_code,
    delivery_member_key,
    delivery_owner_phone,
    delivery_owner_name
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
    coalesce(order_payload->>'groupCode', ''),
    coalesce(order_payload->>'deliveryMemberKey', ''),
    coalesce(order_payload->>'deliveryOwnerPhone', ''),
    coalesce(order_payload->>'deliveryOwnerName', '')
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
    custom_photo_note,
    owner_member_key,
    owner_phone,
    owner_name
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
    coalesce(item."customPhotoNote", ''),
    coalesce(item."ownerMemberKey", ''),
    coalesce(item."ownerPhone", ''),
    coalesce(item."ownerName", '')
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
    "customPhotoNote" text,
    "ownerMemberKey" text,
    "ownerPhone" text,
    "ownerName" text
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
      where status = 'بانتظار الدفع'
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
      where status = 'بانتظار الدفع'
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

-- نسخة بالدولار — التطبيق يرسل p_amount_usd بدلاً من p_amount_syp
create or replace function public.create_wallet_topup(
  p_phone text,
  p_name text,
  p_amount_usd numeric
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  cleaned_phone text := regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g');
  usd_rate numeric;
  requested_usd numeric := greatest(round(coalesce(p_amount_usd, 0), 2), 0.01);
  target_customer_id uuid;
  candidate_amount numeric;
  credit_syp integer;
  expires timestamptz := now() + interval '5 minutes';
  attempt integer;
  max_attempts integer := 40;
  inserted_topup_id uuid;
begin
  if cleaned_phone = '' then raise exception 'phone is required'; end if;

  select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
  usd_rate := coalesce(usd_rate, 13000);
  credit_syp := round(requested_usd * usd_rate)::integer;

  target_customer_id := public.ensure_customer(
    cleaned_phone,
    coalesce(nullif(trim(coalesce(p_name, '')), ''), 'عميل طلبية'),
    'دمشق', '', '', ''
  );

  update public.wallet_topups
  set status = 'منتهي'
  where status = 'بانتظار الدفع' and expires_at <= now();

  for attempt in 0..max_attempts loop
    candidate_amount := requested_usd - (attempt * 0.01);
    if candidate_amount <= 0 then exit; end if;

    if exists (
      select 1 from public.orders
      where payment_status = 'بانتظار الدفع'
        and payment_currency = 'USD' and payment_amount = candidate_amount
        and (payment_expires_at is null or payment_expires_at > now())
    ) then continue; end if;

    if exists (
      select 1 from public.order_issue_payments
      where status = 'بانتظار الدفع'
        and payment_currency = 'USD' and payment_amount = candidate_amount
        and expires_at > now()
    ) then continue; end if;

    begin
      insert into public.wallet_topups (
        customer_id, phone, requested_amount_syp, payment_amount,
        payment_currency, status, expires_at
      )
      values (
        target_customer_id, cleaned_phone, credit_syp, candidate_amount,
        'USD', 'بانتظار الدفع', expires
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

revoke all on function public.create_wallet_topup(text, text, numeric) from public;
grant execute on function public.create_wallet_topup(text, text, numeric) to anon, authenticated;

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

-- يحدّث خيار عنصر طلب (مقاس أو لون) باختيار الزبون من التطبيق — تدفق حل
-- المشاكل ذاتياً: المشرف يعرض «الخيارات المتاحة» في ملاحظة المشكلة والزبون
-- يختار بلمسة. الحقول مقيدة بقائمة بيضاء ولا يمس السعر/الكمية/الحالة.
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

-- النواة service_role فقط — الزبائن يمرون عبر الغلاف الموقّع بالجلسة أدناه
-- (نمط 20260711_harden_customer_payments نفسه).
revoke all on function public.submit_order_option_fix(text, text, text, text) from public, anon, authenticated;
grant execute on function public.submit_order_option_fix(text, text, text, text) to service_role;

-- Ownership helpers are defined before the session wrappers that call them.
create or replace function public.customer_owns_order_item_row(p_order_item_id uuid, p_customer_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.order_items oi
    join public.orders o on o.id = oi.order_id
    left join public.cart_group_members cgm
      on cgm.group_id = o.group_id and cgm.member_key = oi.owner_member_key
    left join public.customers owner_customer
      on regexp_replace(owner_customer.phone, '\s+', '', 'g') = regexp_replace(oi.owner_phone, '\s+', '', 'g')
    where oi.id = p_order_item_id
      and (
        cgm.customer_id = p_customer_id
        or owner_customer.id = p_customer_id
        or (oi.owner_member_key = '' and oi.owner_phone = '' and o.customer_id = p_customer_id)
      )
  );
$$;

revoke all on function public.customer_owns_order_item_row(uuid, uuid) from public, anon, authenticated;
grant execute on function public.customer_owns_order_item_row(uuid, uuid) to service_role;

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
  updated_count integer;
  clean_value text := left(trim(coalesce(p_value, '')), 120);
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if clean_value = '' or p_field not in ('size', 'color') then return false; end if;
  if p_field = 'size' then
    update public.order_items oi set size = clean_value
    where oi.order_id = target_order_id
      and (oi.id::text = p_product_id or oi.product_id = p_product_id)
      and public.customer_owns_order_item_row(oi.id, target_customer_id);
  else
    update public.order_items oi set color = clean_value
    where oi.order_id = target_order_id
      and (oi.id::text = p_product_id or oi.product_id = p_product_id)
      and public.customer_owns_order_item_row(oi.id, target_customer_id);
  end if;
  get diagnostics updated_count = row_count;
  return updated_count > 0;
end;
$$;

revoke all on function public.submit_order_option_fix(text, text, text, text, text) from public;
grant execute on function public.submit_order_option_fix(text, text, text, text, text) to anon, authenticated;

create or replace function public.customer_owns_order_item(
  p_order_id text,
  p_product_or_item_id text,
  p_customer_id uuid
)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.order_items oi
    join public.orders o on o.id = oi.order_id
    left join public.cart_group_members cgm
      on cgm.group_id = o.group_id and cgm.member_key = oi.owner_member_key
    left join public.customers owner_customer
      on regexp_replace(owner_customer.phone, '\s+', '', 'g') = regexp_replace(oi.owner_phone, '\s+', '', 'g')
    where oi.order_id = p_order_id
      and (oi.id::text = p_product_or_item_id or oi.product_id = p_product_or_item_id)
      and (
        cgm.customer_id = p_customer_id
        or owner_customer.id = p_customer_id
        or (
          oi.owner_member_key = '' and oi.owner_phone = ''
          and o.customer_id = p_customer_id
        )
      )
  );
$$;

revoke all on function public.customer_owns_order_item(text, text, uuid) from public, anon, authenticated;
grant execute on function public.customer_owns_order_item(text, text, uuid) to service_role;

create or replace function public.customer_owns_order_item_row(p_order_item_id uuid, p_customer_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.order_items oi
    join public.orders o on o.id = oi.order_id
    left join public.cart_group_members cgm
      on cgm.group_id = o.group_id and cgm.member_key = oi.owner_member_key
    left join public.customers owner_customer
      on regexp_replace(owner_customer.phone, '\s+', '', 'g') = regexp_replace(oi.owner_phone, '\s+', '', 'g')
    where oi.id = p_order_item_id
      and (
        cgm.customer_id = p_customer_id
        or owner_customer.id = p_customer_id
        or (oi.owner_member_key = '' and oi.owner_phone = '' and o.customer_id = p_customer_id)
      )
  );
$$;

revoke all on function public.customer_owns_order_item_row(uuid, uuid) from public, anon, authenticated;
grant execute on function public.customer_owns_order_item_row(uuid, uuid) to service_role;

-- يعلّم مشكلة منظمة كمحلولة بقيمة الزبون (v63). نواة service_role + غلاف جلسة.
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
        then elem || jsonb_build_object('resolved', true, 'resolvedValue', left(coalesce(p_resolved_value, ''), 2000))
        else elem end
    )
    from jsonb_array_elements(o.issues) elem
  )
  where o.id = target_order_id
    and jsonb_typeof(o.issues) = 'array'
    and exists (select 1 from jsonb_array_elements(o.issues) e where e->>'id' = p_issue_id);
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
  if exists (
    select 1 from public.orders o, jsonb_array_elements(o.issues) issue
    where o.id = target_order_id and issue->>'id' = p_issue_id and issue->>'type' = 'payment'
  ) then return false; end if;
  if not exists (
    select 1
    from public.orders o, jsonb_array_elements(o.issues) issue
    where o.id = target_order_id
      and issue->>'id' = p_issue_id
      and (
        (coalesce(issue->>'itemId', '') <> '' and public.customer_owns_order_item(o.id, issue->>'itemId', target_customer_id))
        or (coalesce(issue->>'itemId', '') = '' and o.customer_id = target_customer_id)
      )
  ) then return false; end if;
  return public.submit_order_issue_resolve(target_order_id, p_issue_id, p_resolved_value);
end;
$$;

revoke all on function public.submit_order_issue_resolve(text, text, text, text) from public;
grant execute on function public.submit_order_issue_resolve(text, text, text, text) to anon, authenticated;

create or replace function public.submit_order_issue_resolve(
  target_order_id text,
  p_issue_id text,
  p_resolved_value text,
  p_resolved_photo_data_url text,
  p_session_token text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  clean_photo text := trim(coalesce(p_resolved_photo_data_url, ''));
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if clean_photo <> '' and (
    length(clean_photo) > 4000000
    or clean_photo !~ '^data:image/(png|jpeg|jpg|webp);base64,[A-Za-z0-9+/=[:space:]]+$'
  ) then return false; end if;
  if exists (
    select 1 from public.orders o, jsonb_array_elements(o.issues) issue
    where o.id = target_order_id and issue->>'id' = p_issue_id and issue->>'type' = 'payment'
  ) then return false; end if;
  if not exists (
    select 1
    from public.orders o, jsonb_array_elements(o.issues) issue
    where o.id = target_order_id
      and issue->>'id' = p_issue_id
      and (
        (coalesce(issue->>'itemId', '') <> '' and public.customer_owns_order_item(o.id, issue->>'itemId', target_customer_id))
        or (coalesce(issue->>'itemId', '') = '' and o.customer_id = target_customer_id)
      )
  ) then return false; end if;
  if clean_photo <> '' and not exists (
    select 1 from public.orders o, jsonb_array_elements(o.issues) issue
    where o.id = target_order_id and issue->>'id' = p_issue_id
      and (issue->>'requestPhoto' = 'true' or issue->>'responseType' = 'image')
  ) then return false; end if;

  if not public.submit_order_issue_resolve(
    target_order_id,
    p_issue_id,
    left(coalesce(p_resolved_value, ''), 2000)
  ) then return false; end if;

  if clean_photo <> '' then
    update public.orders o
    set issues = (
      select jsonb_agg(
        case when issue->>'id' = p_issue_id
          then issue || jsonb_build_object('resolvedPhotoDataUrl', clean_photo)
          else issue end
      ) from jsonb_array_elements(o.issues) issue
    )
    where o.id = target_order_id and exists (
      select 1 from jsonb_array_elements(o.issues) issue
      where issue->>'id' = p_issue_id
    );
  end if;
  return true;
end;
$$;

revoke all on function public.submit_order_issue_resolve(text, text, text, text, text) from public;
grant execute on function public.submit_order_issue_resolve(text, text, text, text, text) to anon, authenticated;

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
          'orderItemId', oi.id,
          'title', oi.title,
          'image', oi.image,
          'color', oi.color,
          'size', oi.size,
          'quantity', oi.quantity,
          'priceSyp', oi.price_syp,
          'sourceLink', oi.source_link,
          'customText', oi.custom_text,
          'customPhotoDataUrl', oi.custom_photo,
          'customPhotoNote', oi.custom_photo_note,
          'ownerMemberKey', oi.owner_member_key,
          'ownerPhone', oi.owner_phone,
          'ownerName', oi.owner_name
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
      'groupCode', o.group_code,
      'groupMembers', case when o.group_id is null then '[]'::jsonb else (
        select coalesce(jsonb_agg(jsonb_build_object(
          'memberKey', cgm.member_key,
          'phone', cgm.phone,
          'name', cgm.display_name,
          'role', cgm.role
        ) order by case when cgm.role = 'host' then 0 else 1 end, cgm.joined_at), '[]'::jsonb)
        from public.cart_group_members cgm
        where cgm.group_id = o.group_id
      ) end,
      'deliveryMemberKey', o.delivery_member_key,
      'deliveryOwnerPhone', o.delivery_owner_phone,
      'deliveryOwnerName', o.delivery_owner_name
    ) order by o.created_at desc), '[]'::jsonb)
  from public.orders o
  where (target_customer_id is not null and o.customer_id = target_customer_id)
     or (target_phone <> '' and o.phone = target_phone)
     or (
       o.group_id is not null
       and exists (
         select 1
         from public.cart_group_members cgm
         where cgm.group_id = o.group_id
           and (
             (target_customer_id is not null and cgm.customer_id = target_customer_id)
             or (target_phone <> '' and regexp_replace(cgm.phone, '\s+', '', 'g') = regexp_replace(target_phone, '\s+', '', 'g'))
           )
       )
     );
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
  where group_id = p_group_id and member_key = target_member_key;

  insert into public.cart_group_items (
    group_id, customer_id, member_key, local_item_id, payload, price_usd, price_syp, quantity
  )
  select
    p_group_id,
    p_customer_id,
    target_member_key,
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
        'memberKey', cgm.member_key,
        'phone', cgm.phone,
        'name', cgm.display_name,
        'role', cgm.role
      ) order by cgm.joined_at), '[]'::jsonb)
      from public.cart_group_members cgm
      where cgm.group_id = g.id
    ),
    'items', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'ownerMemberKey', cgm.member_key,
        'ownerPhone', cgm.phone,
        'ownerName', cgm.display_name,
        'item', cgi.payload
      ) order by cgi.updated_at), '[]'::jsonb)
      from public.cart_group_items cgi
      join public.cart_group_members cgm
        on cgm.group_id = cgi.group_id and cgm.member_key = cgi.member_key
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

  insert into public.cart_group_members (group_id, customer_id, member_key, phone, display_name, role)
  values (group_id, customer_id, customer_id::text, regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g'), coalesce(nullif(trim(p_name), ''), 'صاحب الطلب'), 'host')
  on conflict (group_id, member_key) do update set
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

  insert into public.cart_group_members (group_id, customer_id, member_key, phone, display_name, role)
  values (found_group.id, customer_id, customer_id::text, regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g'), coalesce(nullif(trim(p_name), ''), 'عضو'), 'member')
  on conflict (group_id, member_key) do update set
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

-- ============================================================================
-- رصيد المحفظة بالدولار — يحوّل رصيد الليرة حسب سعر الصرف الحالي
-- ============================================================================

create or replace function public.get_wallet_balance_usd(p_phone text)
returns numeric
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  cleaned_phone text := regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g');
  balance_syp integer := 0;
  usd_rate numeric;
begin
  if cleaned_phone = '' then return 0; end if;

  select coalesce(sum(wt.amount_syp), 0)::integer into balance_syp
  from public.wallet_transactions wt
  join public.customers c on c.id = wt.customer_id
  where c.phone = cleaned_phone;

  if balance_syp <= 0 then return 0; end if;

  select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
  usd_rate := coalesce(usd_rate, 13000);

  return round(balance_syp / usd_rate, 2);
end;
$$;

revoke all on function public.get_wallet_balance_usd(text) from public;
grant execute on function public.get_wallet_balance_usd(text) to anon, authenticated;

-- ============================================================================
-- خصم من المحفظة عند تأكيد طلب
-- ============================================================================

create or replace function public.wallet_spend(p_phone text, p_amount_usd numeric, p_order_id text)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  cleaned_phone text := regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g');
  found_customer_id uuid;
  balance_syp integer := 0;
  usd_rate numeric;
  spend_syp integer;
  new_balance_syp integer;
begin
  if cleaned_phone = '' then raise exception 'phone is required'; end if;
  if coalesce(p_amount_usd, 0) <= 0 then raise exception 'amount must be positive'; end if;

  select id into found_customer_id from public.customers where phone = cleaned_phone;
  if found_customer_id is null then raise exception 'customer not found'; end if;

  select coalesce(sum(amount_syp), 0)::integer into balance_syp
  from public.wallet_transactions
  where customer_id = found_customer_id;

  select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
  usd_rate := coalesce(usd_rate, 13000);

  spend_syp := least(round(p_amount_usd * usd_rate)::integer, balance_syp);
  if spend_syp <= 0 then raise exception 'insufficient balance'; end if;

  insert into public.wallet_transactions (
    customer_id, phone, amount_syp, amount_usd, kind, note, created_by, metadata
  )
  values (
    found_customer_id,
    cleaned_phone,
    -spend_syp,
    -round(p_amount_usd, 2),
    'order_payment',
    'خصم من المحفظة للطلب ' || coalesce(p_order_id, ''),
    'app',
    jsonb_build_object('orderId', coalesce(p_order_id, ''), 'amountUsd', p_amount_usd)
  );

  select coalesce(sum(amount_syp), 0)::integer into new_balance_syp
  from public.wallet_transactions
  where customer_id = found_customer_id;

  return round(greatest(new_balance_syp, 0) / usd_rate, 2);
end;
$$;

revoke all on function public.wallet_spend(text, numeric, text) from public;
grant execute on function public.wallet_spend(text, numeric, text) to anon, authenticated;

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
  usd_rate := case when usd_rate > 0 then usd_rate else 13000 end;

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
  max_attempts integer := 120;
begin
  if target_order_id is null then raise exception 'order id is required'; end if;
  if item_count = 0 then raise exception 'order items are required'; end if;
  if order_total_syp <= 0 then raise exception 'order total must be positive'; end if;
  if normalized_currency not in ('SYP', 'USD') then raise exception 'invalid currency'; end if;
  if coalesce(p_wallet_spend_usd, 0) < 0 then raise exception 'invalid wallet amount'; end if;

  target_customer_id := public.require_customer_session(p_session_token, null);
  select phone into account_phone from public.customers where id = target_customer_id;

  perform pg_advisory_xact_lock(hashtext('shamcash-payment-' || normalized_currency));

  update public.orders
  set payment_status = 'فشل المطابقة'
  where payment_status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and payment_expires_at is not null
    and payment_expires_at <= now();
  update public.wallet_topups set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and expires_at <= now();
  update public.order_issue_payments set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and expires_at <= now();

  -- Keep lock ordering consistent with webhook confirmation: payment key,
  -- then any rows being expired, then the per-customer wallet key.
  perform pg_advisory_xact_lock(hashtext('wallet-' || target_customer_id::text));

  select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
  usd_rate := case when usd_rate > 0 then usd_rate else 13000 end;
  available_syp := public.available_wallet_syp(target_customer_id);
  wallet_requested_syp := round(coalesce(p_wallet_spend_usd, 0) * usd_rate)::integer;

  if wallet_requested_syp > available_syp then raise exception 'insufficient wallet balance'; end if;
  if wallet_requested_syp > order_total_syp then raise exception 'wallet amount exceeds order total'; end if;
  remaining_syp := order_total_syp - wallet_requested_syp;

  if remaining_syp = 0 then
    insert into public.orders (
      id, customer_id, customer_name, phone, city, address, total_syp,
      payment_status, status_index, qadmous_number, created_at, paid_at,
      payment_amount, payment_currency, payment_expires_at, payment_matched_by,
      group_id, group_code, wallet_reserved_syp, payment_destination,
      delivery_member_key, delivery_owner_phone, delivery_owner_name
    )
    values (
      target_order_id, target_customer_id,
      coalesce(nullif(order_payload->>'customer', ''), 'عميل طلبية'),
      coalesce(account_phone, 'غير محدد'),
      coalesce(nullif(order_payload->>'city', ''), 'غير محدد'),
      coalesce(nullif(order_payload->>'address', ''), 'عنوان غير مكتمل'),
      order_total_syp, 'مدفوع', 1, '', current_date, current_date,
      null, normalized_currency, now(), 'wallet-only',
      target_group_id, coalesce(order_payload->>'groupCode', ''),
      wallet_requested_syp, coalesce(order_payload->>'store', ''),
      coalesce(order_payload->>'deliveryMemberKey', ''),
      coalesce(order_payload->>'deliveryOwnerPhone', ''),
      coalesce(order_payload->>'deliveryOwnerName', '')
    );

    insert into public.order_items (
      order_id, product_id, title, image, color, size, quantity, price_syp, source_link,
      custom_text, custom_photo, custom_photo_note,
      owner_member_key, owner_phone, owner_name
    )
    select
      target_order_id, item.id, item.title, item.image, item.color, item.size,
      greatest(coalesce(item.quantity, 1), 1), greatest(coalesce(item."priceSyp", 0), 0), item."sourceLink",
      coalesce(item."customText", ''), coalesce(item."customPhotoDataUrl", ''), coalesce(item."customPhotoNote", ''),
      coalesce(item."ownerMemberKey", ''), coalesce(item."ownerPhone", ''), coalesce(item."ownerName", '')
    from jsonb_to_recordset(order_payload->'items') as item(
      id text, title text, image text, color text, size text,
      quantity integer, "priceSyp" integer, "sourceLink" text,
      "customText" text, "customPhotoDataUrl" text, "customPhotoNote" text,
      "ownerMemberKey" text, "ownerPhone" text, "ownerName" text
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
        group_id, group_code, wallet_reserved_syp, payment_destination,
        delivery_member_key, delivery_owner_phone, delivery_owner_name
      )
      values (
        target_order_id, target_customer_id,
        coalesce(nullif(order_payload->>'customer', ''), 'عميل طلبية'),
        coalesce(account_phone, 'غير محدد'),
        coalesce(nullif(order_payload->>'city', ''), 'غير محدد'),
        coalesce(nullif(order_payload->>'address', ''), 'عنوان غير مكتمل'),
        order_total_syp, 'بانتظار الدفع', 0, '', current_date,
        candidate_amount, normalized_currency, expires,
        target_group_id, coalesce(order_payload->>'groupCode', ''),
        wallet_requested_syp, coalesce(order_payload->>'store', ''),
        coalesce(order_payload->>'deliveryMemberKey', ''),
        coalesce(order_payload->>'deliveryOwnerPhone', ''),
        coalesce(order_payload->>'deliveryOwnerName', '')
      );

      insert into public.order_items (
        order_id, product_id, title, image, color, size, quantity, price_syp, source_link,
        custom_text, custom_photo, custom_photo_note,
        owner_member_key, owner_phone, owner_name
      )
      select
        target_order_id, item.id, item.title, item.image, item.color, item.size,
        greatest(coalesce(item.quantity, 1), 1), greatest(coalesce(item."priceSyp", 0), 0), item."sourceLink",
        coalesce(item."customText", ''), coalesce(item."customPhotoDataUrl", ''), coalesce(item."customPhotoNote", ''),
        coalesce(item."ownerMemberKey", ''), coalesce(item."ownerPhone", ''), coalesce(item."ownerName", '')
      from jsonb_to_recordset(order_payload->'items') as item(
        id text, title text, image text, color text, size text,
        quantity integer, "priceSyp" integer, "sourceLink" text,
        "customText" text, "customPhotoDataUrl" text, "customPhotoNote" text,
        "ownerMemberKey" text, "ownerPhone" text, "ownerName" text
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

-- Shared-order wrapper. The payment/wallet transaction remains in the
-- hardened create_pending_order implementation above; this wrapper only
-- persists line ownership and the selected delivery member afterwards in the
-- same database transaction.
create or replace function public.create_pending_order_v2(
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
  result jsonb;
  target_order_id text;
  target_group_id uuid;
  selected_delivery_key text := '';
  selected_delivery_phone text := '';
  selected_delivery_name text := '';
begin
  result := public.create_pending_order(order_payload, currency, p_session_token, p_wallet_spend_usd);
  target_order_id := result->>'orderId';

  select o.group_id into target_group_id
  from public.orders o
  where o.id = target_order_id;

  if target_group_id is not null then
    select cgm.member_key, cgm.phone, cgm.display_name
    into selected_delivery_key, selected_delivery_phone, selected_delivery_name
    from public.cart_group_members cgm
    where cgm.group_id = target_group_id
      and cgm.member_key = left(coalesce(order_payload->>'deliveryMemberKey', ''), 200)
    limit 1;
  end if;

  update public.orders o
  set delivery_member_key = coalesce(selected_delivery_key, ''),
      delivery_owner_phone = coalesce(nullif(selected_delivery_phone, ''), o.phone),
      delivery_owner_name = coalesce(nullif(selected_delivery_name, ''), o.customer_name)
  where o.id = target_order_id;

  with payload_items as (
    select
      item->>'id' as product_id,
      left(coalesce(item->>'ownerMemberKey', ''), 200) as owner_member_key,
      left(coalesce(item->>'ownerPhone', ''), 80) as owner_phone,
      left(coalesce(item->>'ownerName', ''), 200) as owner_name,
      row_number() over (partition by item->>'id' order by ordinal) as occurrence
    from jsonb_array_elements(order_payload->'items') with ordinality as source(item, ordinal)
  ), db_items as (
    select
      oi.id,
      oi.product_id,
      row_number() over (partition by oi.product_id order by oi.created_at, oi.id) as occurrence
    from public.order_items oi
    where oi.order_id = target_order_id
  ), paired as (
    select db.id, member.member_key as owner_member_key,
      member.phone as owner_phone, member.display_name as owner_name
    from db_items db
    join payload_items payload
      on payload.product_id = db.product_id and payload.occurrence = db.occurrence
    join public.cart_group_members member
      on member.group_id = target_group_id and member.member_key = payload.owner_member_key
    where target_group_id is not null
      and exists (
        select 1 from public.cart_group_items group_item
        where group_item.group_id = target_group_id
          and group_item.member_key = member.member_key
          and group_item.payload->>'id' = db.product_id
      )
  )
  update public.order_items oi
  set owner_member_key = paired.owner_member_key,
      owner_phone = paired.owner_phone,
      owner_name = paired.owner_name
  from paired
  where oi.id = paired.id;

  return result;
end;
$$;

revoke all on function public.create_pending_order_v2(jsonb, text, text, numeric) from public;
grant execute on function public.create_pending_order_v2(jsonb, text, text, numeric) to anon, authenticated;

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
  usd_rate := case when usd_rate > 0 then usd_rate else 13000 end;
  credit_syp := round(requested_usd * usd_rate)::integer;

  perform pg_advisory_xact_lock(hashtext('shamcash-payment-USD'));
  update public.orders set payment_status = 'فشل المطابقة'
  where payment_status = 'بانتظار الدفع'
    and payment_currency = 'USD'
    and payment_expires_at is not null and payment_expires_at <= now();
  update public.wallet_topups set status = 'منتهي'
  where status = 'بانتظار الدفع' and payment_currency = 'USD' and expires_at <= now();
  update public.order_issue_payments set status = 'منتهي'
  where status = 'بانتظار الدفع' and payment_currency = 'USD' and expires_at <= now();

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
  normalized_currency text := upper(trim(coalesce(p_currency, '')));
begin
  if normalized_currency not in ('SYP', 'USD') then
    raise exception 'invalid currency';
  end if;

  target_customer_id := public.require_customer_session(p_session_token, null);
  perform pg_advisory_xact_lock(hashtext('shamcash-payment-' || normalized_currency));

  -- Serialize issue-payment creation for the same order even if callers choose
  -- different currencies, and bind the order to the authenticated customer.
  perform 1
  from public.orders
  where id = nullif(p_order_id, '') and customer_id = target_customer_id
  for update;
  if not found then
    raise exception 'order not found';
  end if;

  return public.create_order_issue_payment(p_order_id, p_amount_usd, normalized_currency);
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
  normalized_currency text := upper(trim(coalesce(match_currency, '')));
begin
  if coalesce(match_amount, 0) <= 0 or normalized_currency not in ('SYP', 'USD') then
    return jsonb_build_object('matched', false, 'reason', 'invalid_payment');
  end if;

  perform pg_advisory_xact_lock(hashtext('shamcash-payment-' || normalized_currency));

  update public.orders
  set payment_status = 'فشل المطابقة'
  where payment_status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and payment_expires_at is not null
    and payment_expires_at <= now();

  select count(*) into match_count
  from public.orders
  where payment_status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and payment_amount = match_amount
    and (payment_expires_at is null or payment_expires_at > now());

  if match_count = 0 then return jsonb_build_object('matched', false, 'reason', 'not_found'); end if;
  if match_count > 1 then return jsonb_build_object('matched', false, 'reason', 'ambiguous'); end if;

  select * into matched_order
  from public.orders
  where payment_status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and payment_amount = match_amount
    and (payment_expires_at is null or payment_expires_at > now())
  limit 1
  for update;

  -- An explicit admin update can win the row race without taking the payment
  -- advisory lock. Treat that as an idempotent miss instead of dereferencing a
  -- null row and creating a duplicate event.
  if not found then
    return jsonb_build_object('matched', false, 'reason', 'not_found');
  end if;

  perform public.apply_order_wallet_reservation(matched_order.id);

  update public.orders
  set payment_status = 'مدفوع', status_index = 1, paid_at = current_date,
      payment_matched_by = 'sham-cash-webhook'
  where id = matched_order.id and payment_status = 'بانتظار الدفع';

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
  normalized_currency text := upper(trim(coalesce(match_currency, '')));
begin
  if coalesce(match_amount, 0) <= 0 or normalized_currency not in ('SYP', 'USD') then
    return jsonb_build_object('matched', false, 'reason', 'invalid_payment');
  end if;

  perform pg_advisory_xact_lock(hashtext('shamcash-payment-' || normalized_currency));

  update public.wallet_topups set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and expires_at <= now();

  select count(*) into match_count
  from public.wallet_topups
  where status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and payment_amount = match_amount
    and expires_at > now();

  if match_count = 0 then return jsonb_build_object('matched', false, 'reason', 'not_found'); end if;
  if match_count > 1 then return jsonb_build_object('matched', false, 'reason', 'ambiguous'); end if;

  select * into matched_topup
  from public.wallet_topups
  where status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and payment_amount = match_amount
    and expires_at > now()
  limit 1
  for update;

  if not found then
    return jsonb_build_object('matched', false, 'reason', 'not_found');
  end if;

  credit_amount := greatest(matched_topup.requested_amount_syp, 0);
  if credit_amount <= 0 then raise exception 'invalid wallet top-up credit'; end if;

  update public.wallet_topups
  set status = 'مدفوع', paid_at = now(),
      notification_text = left(coalesce(raw_notification_text, ''), 1200)
  where id = matched_topup.id and status = 'بانتظار الدفع';

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
  normalized_currency text := upper(trim(coalesce(match_currency, '')));
  order_count integer := 0;
  topup_count integer := 0;
  issue_count integer := 0;
  matched_issue public.order_issue_payments%rowtype;
  safe_notification_text text := left(coalesce(notification_text, ''), 1200);
begin
  if coalesce(match_amount, 0) <= 0 or normalized_currency not in ('SYP', 'USD') then
    return jsonb_build_object('matched', false, 'reason', 'invalid_payment');
  end if;

  -- Creation and confirmation share this key. This closes the window where a
  -- webhook could observe "not found" while a matching intent was committing.
  perform pg_advisory_xact_lock(hashtext('shamcash-payment-' || normalized_currency));

  update public.orders
  set payment_status = 'فشل المطابقة'
  where payment_status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and payment_expires_at is not null
    and payment_expires_at <= now();
  update public.wallet_topups
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and expires_at <= now();
  update public.order_issue_payments
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and expires_at <= now();

  select count(*) into order_count
  from public.orders
  where payment_status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and payment_amount = match_amount
    and (payment_expires_at is null or payment_expires_at > now());

  select count(*) into topup_count
  from public.wallet_topups
  where status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
    and payment_amount = match_amount
    and expires_at > now();

  select count(*) into issue_count
  from public.order_issue_payments
  where status = 'بانتظار الدفع'
    and payment_currency = normalized_currency
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
      and payment_currency = normalized_currency
      and payment_amount = match_amount
      and expires_at > now()
    limit 1
    for update;

    if not found then
      return jsonb_build_object('matched', false, 'reason', 'not_found');
    end if;

    update public.order_issue_payments
    set status = 'مدفوع',
        paid_at = now(),
        notification_text = safe_notification_text
    where id = matched_issue.id and status = 'بانتظار الدفع';

    update public.orders
    set payment_issue = false,
        payment_issue_note = '',
        extra_amount_usd = 0
    where id = matched_issue.order_id;

    insert into public.order_events (order_id, status_index, title, note)
    select matched_issue.order_id, status_index,
           'تم حل مشكلة الدفع', 'تمت مطابقة الدفعة الإضافية عبر شام كاش'
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
    return public.confirm_wallet_topup_by_amount(
      match_amount, normalized_currency, safe_notification_text
    );
  end if;

  return public.confirm_payment_by_amount(
    match_amount, normalized_currency, safe_notification_text
  ) || jsonb_build_object('type', 'order_payment');
end;
$$;

revoke all on function public.confirm_shamcash_payment_by_amount(numeric, text, text)
  from public, anon, authenticated;
grant execute on function public.confirm_shamcash_payment_by_amount(numeric, text, text)
  to service_role;

create or replace function public.process_shamcash_payment_event(
  p_event_id text,
  p_amount numeric,
  p_currency text,
  p_notification_text text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_event_id text := trim(coalesce(p_event_id, ''));
  normalized_amount numeric := round(coalesce(p_amount, 0), 2);
  normalized_currency text := upper(trim(coalesce(p_currency, '')));
  found_event public.payment_events%rowtype;
  confirmation_result jsonb;
  merged_result jsonb;
  terminal_status text;
  resolved_matched_type text;
  resolved_matched_id text;
  effective_notification_text text;
begin
  if normalized_event_id = '' or length(normalized_event_id) > 160 then
    raise exception 'invalid payment event id';
  end if;
  if normalized_amount <= 0 or normalized_currency not in ('SYP', 'USD') then
    raise exception 'invalid parsed payment';
  end if;

  select * into found_event
  from public.payment_events
  where event_id = normalized_event_id
  for update;

  if not found then
    raise exception 'payment event not found';
  end if;
  if found_event.provider <> 'shamcash'
     or found_event.package_name <> 'com.shmacash.shamcash' then
    raise exception 'payment event source mismatch';
  end if;
  if found_event.parsed_amount is null
     or found_event.parsed_amount <> normalized_amount
     or found_event.parsed_currency is null
     or found_event.parsed_currency <> normalized_currency then
    raise exception 'payment event parse mismatch';
  end if;

  -- Replays of the same listener event return the durable first result. The
  -- row lock makes two simultaneous deliveries of one event exactly-once.
  if found_event.status in ('matched', 'ambiguous', 'rejected', 'duplicate') then
    return coalesce(found_event.result, '{}'::jsonb);
  end if;
  if found_event.status = 'unmatched'
     and found_event.received_at <= now() - interval '2 minutes' then
    return coalesce(found_event.result, '{}'::jsonb);
  end if;
  if found_event.status not in ('received', 'error', 'unmatched') then
    raise exception 'invalid payment event state';
  end if;

  perform pg_advisory_xact_lock(hashtext('shamcash-payment-' || normalized_currency));

  effective_notification_text := left(
    coalesce(nullif(found_event.notification_text, ''), p_notification_text, ''),
    1200
  );
  confirmation_result := public.confirm_shamcash_payment_by_amount(
    normalized_amount,
    normalized_currency,
    effective_notification_text
  );

  if coalesce((confirmation_result->>'matched')::boolean, false) then
    terminal_status := 'matched';
    resolved_matched_type := coalesce(nullif(confirmation_result->>'type', ''), 'order_payment');
    resolved_matched_id := case resolved_matched_type
      when 'wallet_topup' then nullif(confirmation_result->>'topUpId', '')
      when 'order_issue_payment' then coalesce(
        nullif(confirmation_result->>'issuePaymentId', ''),
        nullif(confirmation_result->>'orderId', '')
      )
      else nullif(confirmation_result->>'orderId', '')
    end;
  elsif confirmation_result->>'reason' = 'ambiguous' then
    terminal_status := 'ambiguous';
    resolved_matched_type := null;
    resolved_matched_id := null;
  else
    terminal_status := 'unmatched';
    resolved_matched_type := null;
    resolved_matched_id := null;
  end if;

  -- Preserve immutable audit fields (notably bodyHash) written during the
  -- authenticated insert while allowing the confirmation result to win on
  -- matched/reason/type identifiers.
  merged_result := coalesce(found_event.result, '{}'::jsonb)
    || coalesce(confirmation_result, '{}'::jsonb);

  update public.payment_events
  set status = terminal_status,
      matched_type = resolved_matched_type,
      matched_id = resolved_matched_id,
      result = merged_result,
      updated_at = now()
  where id = found_event.id;

  return merged_result;
end;
$$;

revoke all on function public.process_shamcash_payment_event(text, numeric, text, text)
  from public, anon, authenticated;
grant execute on function public.process_shamcash_payment_event(text, numeric, text, text)
  to service_role;

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
    p_phone => p_phone,
    p_name => p_name,
    p_governorate => p_governorate,
    p_qadmous_branch => p_qadmous_branch,
    p_city => p_city,
    p_details => p_details
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
  usd_rate := case when usd_rate > 0 then usd_rate else 13000 end;
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
  from public.orders o
  where id = target_order_id
    and (
      customer_id = target_customer_id
      or (
        group_id is not null
        and exists (
          select 1 from public.cart_group_members cgm
          where cgm.group_id = o.group_id and cgm.customer_id = target_customer_id
        )
      )
    );
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
  updated_count integer;
  clean_photo text := trim(coalesce(p_custom_photo, ''));
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if clean_photo <> '' and (
    length(clean_photo) > 4000000
    or clean_photo !~ '^data:image/(png|jpeg|jpg|webp);base64,[A-Za-z0-9+/=[:space:]]+$'
  ) then return false; end if;
  update public.order_items oi
  set custom_photo = coalesce(nullif(clean_photo, ''), oi.custom_photo),
      custom_text = coalesce(nullif(left(trim(coalesce(p_custom_text, '')), 2000), ''), oi.custom_text)
  where oi.order_id = target_order_id
    and (oi.id::text = p_product_id or oi.product_id = p_product_id)
    and public.customer_owns_order_item_row(oi.id, target_customer_id);
  get diagnostics updated_count = row_count;
  return updated_count > 0;
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
  if p_payment_status is null
     or p_payment_status not in ('بانتظار الدفع', 'مدفوع', 'فشل المطابقة') then
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
revoke all on function public.submit_order(jsonb) from public, anon, authenticated;
revoke all on function public.create_pending_order(jsonb, text) from public, anon, authenticated;
revoke all on function public.create_order_issue_payment(text, numeric, text) from public, anon, authenticated;
revoke all on function public.create_wallet_topup(text, text, integer) from public, anon, authenticated;
revoke all on function public.create_wallet_topup(text, text, numeric) from public, anon, authenticated;
revoke all on function public.get_wallet_topup_status(text) from public, anon, authenticated;
revoke all on function public.get_order_payment_status(text) from public, anon, authenticated;
revoke all on function public.get_customer_account(text) from public, anon, authenticated;
revoke all on function public.get_wallet_balance_usd(text) from public, anon, authenticated;
revoke all on function public.wallet_spend(text, numeric, text) from public, anon, authenticated;
revoke all on function public.upsert_customer_profile(text, text, text, text, text, text) from public, anon, authenticated;
revoke all on function public.update_customer_preferences(text, text, jsonb) from public, anon, authenticated;
revoke all on function public.redeem_coupon(text, text, text, text, integer, numeric) from public, anon, authenticated;
revoke all on function public.submit_order_rating(text, integer, text) from public, anon, authenticated;
revoke all on function public.submit_order_custom_fix(text, text, text, text) from public, anon, authenticated;
revoke all on function public.ensure_customer(text, text, text, text, text, text) from public, anon, authenticated;
revoke all on function public.upsert_customer_from_order(jsonb) from public, anon, authenticated;
revoke all on function public.customer_orders_json(uuid, text) from public, anon, authenticated;

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

-- Exact-only payment guard. A lower collision candidate must never settle a
-- full order, wallet top-up, or issue payment.
create or replace function public.enforce_exact_payment_intent()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  usd_rate numeric;
  required_amount numeric;
  remaining_syp integer;
  metadata_requested_usd text;
begin
  select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
  usd_rate := case when usd_rate > 0 then usd_rate else 13000 end;

  if tg_table_name = 'orders' then
    if new.payment_status <> 'بانتظار الدفع' or new.payment_amount is null then return new; end if;
    remaining_syp := greatest(coalesce(new.total_syp, 0) - coalesce(new.wallet_reserved_syp, 0), 0);
    required_amount := case when new.payment_currency = 'USD'
      then round(remaining_syp / usd_rate, 2) else remaining_syp::numeric end;
  elsif tg_table_name = 'wallet_topups' then
    if new.status <> 'بانتظار الدفع' then return new; end if;
    if new.payment_currency = 'USD' then
      metadata_requested_usd := coalesce(new.metadata->>'requestedUsd', '');
      required_amount := case
        when metadata_requested_usd ~ '^\d+(?:\.\d{1,2})?$' then round(metadata_requested_usd::numeric, 2)
        else round(coalesce(new.requested_amount_syp, 0) / usd_rate, 2) end;
    else
      required_amount := coalesce(new.requested_amount_syp, 0)::numeric;
    end if;
  elsif tg_table_name = 'order_issue_payments' then
    if new.status <> 'بانتظار الدفع' then return new; end if;
    required_amount := case when new.payment_currency = 'USD'
      then round(coalesce(new.requested_amount_usd, 0), 2)
      else round(coalesce(new.requested_amount_usd, 0) * usd_rate) end;
  else
    raise exception 'unsupported payment intent table';
  end if;

  if required_amount <= 0 or new.payment_amount <> required_amount then
    raise exception using errcode = 'P0001',
      message = 'payment amount collision; retry after the existing intent expires';
  end if;
  return new;
end;
$$;
revoke all on function public.enforce_exact_payment_intent() from public, anon, authenticated;
grant execute on function public.enforce_exact_payment_intent() to service_role;

drop trigger if exists orders_exact_payment_amount on public.orders;
create trigger orders_exact_payment_amount before insert on public.orders
for each row execute function public.enforce_exact_payment_intent();
drop trigger if exists wallet_topups_exact_payment_amount on public.wallet_topups;
create trigger wallet_topups_exact_payment_amount before insert on public.wallet_topups
for each row execute function public.enforce_exact_payment_intent();
drop trigger if exists order_issue_exact_payment_amount on public.order_issue_payments;
create trigger order_issue_exact_payment_amount before insert on public.order_issue_payments
for each row execute function public.enforce_exact_payment_intent();

update public.wallet_topups set status = 'منتهي'
where status = 'بانتظار الدفع' and expires_at <= now();
with ranked as (
  select id, row_number() over (
    partition by customer_id order by created_at desc, id desc
  ) as position
  from public.wallet_topups where status = 'بانتظار الدفع'
)
update public.wallet_topups as topup set status = 'منتهي'
from ranked where topup.id = ranked.id and ranked.position > 1;
create unique index if not exists wallet_topups_one_pending_per_customer_uidx
  on public.wallet_topups (customer_id) where status = 'بانتظار الدفع';
