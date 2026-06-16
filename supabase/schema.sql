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
