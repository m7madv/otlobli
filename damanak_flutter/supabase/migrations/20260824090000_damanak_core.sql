create extension if not exists pgcrypto with schema extensions;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null default '',
  full_name text not null default '',
  phone text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.plans (
  id text primary key,
  name_ar text not null,
  monthly_price numeric(10, 2) not null check (monthly_price >= 0),
  yearly_price numeric(10, 2) not null check (yearly_price >= 0),
  max_members integer not null check (max_members > 0),
  monthly_warranties integer not null check (monthly_warranties > 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

insert into public.plans (
  id,
  name_ar,
  monthly_price,
  yearly_price,
  max_members,
  monthly_warranties,
  sort_order
) values
  ('starter', 'بداية', 39, 390, 2, 60, 10),
  ('growth', 'نمو', 99, 990, 5, 250, 20),
  ('scale', 'توسع', 199, 1990, 15, 1200, 30)
on conflict (id) do update set
  name_ar = excluded.name_ar,
  monthly_price = excluded.monthly_price,
  yearly_price = excluded.yearly_price,
  max_members = excluded.max_members,
  monthly_warranties = excluded.monthly_warranties,
  sort_order = excluded.sort_order;

create table public.stores (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 120),
  phone text not null default '',
  city text not null default '',
  country_code text not null default 'SA' check (
    country_code in ('SA', 'AE', 'KW', 'QA', 'BH', 'OM')
  ),
  owner_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.store_members (
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'manager', 'staff')),
  status text not null default 'active' check (status in ('active', 'suspended')),
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (store_id, user_id)
);

create index store_members_user_active_idx
  on public.store_members(user_id, status);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null unique references public.stores(id) on delete cascade,
  plan_id text not null references public.plans(id),
  status text not null check (status in ('trialing', 'active', 'past_due', 'canceled')),
  trial_ends_at timestamptz,
  current_period_start timestamptz,
  current_period_end timestamptz,
  source text not null default 'manual' check (source in ('trial', 'activation_code', 'manual', 'store')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 160),
  brand text not null default '',
  barcode text,
  sku text,
  warranty_months integer not null default 12 check (warranty_months between 1 and 120),
  sale_price numeric(12, 2) check (sale_price is null or sale_price >= 0),
  is_active boolean not null default true,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index products_store_barcode_unique
  on public.products(store_id, barcode)
  where barcode is not null and barcode <> '';

create unique index products_store_sku_unique
  on public.products(store_id, sku)
  where sku is not null and sku <> '';

create index products_store_created_idx
  on public.products(store_id, created_at desc);

create table public.warranties (
  id uuid primary key default gen_random_uuid(),
  warranty_number text not null unique,
  store_id uuid not null references public.stores(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  customer_name text not null check (char_length(trim(customer_name)) between 2 and 160),
  customer_phone text not null check (char_length(trim(customer_phone)) between 7 and 30),
  product_name text not null check (char_length(trim(product_name)) between 2 and 200),
  barcode text,
  serial_number text,
  purchase_date date not null,
  expiry_date date not null check (expiry_date >= purchase_date),
  notes text not null default '',
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index warranties_store_created_idx
  on public.warranties(store_id, created_at desc);
create index warranties_store_phone_idx
  on public.warranties(store_id, customer_phone);
create index warranties_store_barcode_idx
  on public.warranties(store_id, barcode);

create table public.maintenance_requests (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  warranty_id uuid not null references public.warranties(id) on delete cascade,
  issue text not null check (char_length(trim(issue)) between 3 and 2000),
  status text not null default 'new' check (status in ('new', 'in_progress', 'completed')),
  assigned_to uuid references auth.users(id) on delete set null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index maintenance_store_updated_idx
  on public.maintenance_requests(store_id, updated_at desc);

create table public.invite_codes (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  code_hash bytea not null unique,
  role text not null check (role in ('manager', 'staff')),
  max_uses integer not null default 1 check (max_uses between 1 and 10),
  used_count integer not null default 0 check (used_count >= 0),
  expires_at timestamptz not null,
  is_active boolean not null default true,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create index invite_codes_store_active_idx
  on public.invite_codes(store_id, is_active, expires_at);

create table public.subscription_requests (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  requested_plan_id text not null references public.plans(id),
  billing_cycle text not null check (billing_cycle in ('monthly', 'yearly')),
  contact_phone text not null,
  status text not null default 'pending' check (status in ('pending', 'contacted', 'completed', 'rejected')),
  requested_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.activation_codes (
  id uuid primary key default gen_random_uuid(),
  code_hash bytea not null unique,
  plan_id text not null references public.plans(id),
  duration_days integer not null check (duration_days between 1 and 730),
  max_uses integer not null default 1 check (max_uses between 1 and 1000),
  used_count integer not null default 0 check (used_count >= 0),
  expires_at timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_logs_store_created_idx
  on public.audit_logs(store_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();
create trigger stores_set_updated_at
before update on public.stores
for each row execute function public.set_updated_at();
create trigger store_members_set_updated_at
before update on public.store_members
for each row execute function public.set_updated_at();
create trigger subscriptions_set_updated_at
before update on public.subscriptions
for each row execute function public.set_updated_at();
create trigger products_set_updated_at
before update on public.products
for each row execute function public.set_updated_at();
create trigger warranties_set_updated_at
before update on public.warranties
for each row execute function public.set_updated_at();
create trigger maintenance_set_updated_at
before update on public.maintenance_requests
for each row execute function public.set_updated_at();
create trigger subscription_requests_set_updated_at
before update on public.subscription_requests
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, email, full_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = case
      when public.profiles.full_name = '' then excluded.full_name
      else public.profiles.full_name
    end;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert or update of email on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_store_member(target_store_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.store_members
    where store_id = target_store_id
      and user_id = (select auth.uid())
      and status = 'active'
  );
$$;

create or replace function public.has_store_role(
  target_store_id uuid,
  allowed_roles text[]
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.store_members
    where store_id = target_store_id
      and user_id = (select auth.uid())
      and status = 'active'
      and role = any(allowed_roles)
  );
$$;

create or replace function public.shares_store(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.store_members mine
    join public.store_members theirs on theirs.store_id = mine.store_id
    where mine.user_id = (select auth.uid())
      and mine.status = 'active'
      and theirs.user_id = target_user_id
  );
$$;

create or replace function public.subscription_is_usable(target_store_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.subscriptions
    where store_id = target_store_id
      and (
        (status = 'trialing' and trial_ends_at > now())
        or
        (status = 'active' and (current_period_end is null or current_period_end > now()))
      )
  );
$$;

create or replace function public.current_warranty_usage(target_store_id uuid)
returns bigint
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  return (
    select count(*)
    from public.warranties
    where store_id = target_store_id
      and created_at >= date_trunc('month', now())
  );
end;
$$;

create or replace function public.create_store_with_trial(
  store_name text,
  store_phone text,
  store_city text,
  store_country_code text
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  created_store_id uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if char_length(trim(store_name)) < 2 then
    raise exception 'STORE_NAME_REQUIRED';
  end if;
  if store_country_code not in ('SA', 'AE', 'KW', 'QA', 'BH', 'OM') then
    raise exception 'COUNTRY_NOT_SUPPORTED';
  end if;

  insert into public.stores(name, phone, city, country_code, owner_id)
  values (
    trim(store_name),
    trim(coalesce(store_phone, '')),
    trim(coalesce(store_city, '')),
    store_country_code,
    (select auth.uid())
  )
  returning id into created_store_id;

  insert into public.store_members(store_id, user_id, role)
  values (created_store_id, (select auth.uid()), 'owner');

  insert into public.subscriptions(
    store_id,
    plan_id,
    status,
    trial_ends_at,
    source
  ) values (
    created_store_id,
    'growth',
    'trialing',
    now() + interval '14 days',
    'trial'
  );

  insert into public.audit_logs(store_id, user_id, action, entity_type, entity_id)
  values (created_store_id, (select auth.uid()), 'store_created', 'store', created_store_id);

  return created_store_id;
end;
$$;

create or replace function public.create_store_invite(
  target_store_id uuid,
  target_role text,
  allowed_uses integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  raw_code text;
  expiry timestamptz := now() + interval '48 hours';
begin
  if not public.has_store_role(target_store_id, array['owner', 'manager']) then
    raise exception 'ROLE_REQUIRED';
  end if;
  if target_role not in ('manager', 'staff') then
    raise exception 'INVALID_ROLE';
  end if;
  if public.has_store_role(target_store_id, array['manager']) and target_role = 'manager' then
    raise exception 'OWNER_REQUIRED';
  end if;
  if allowed_uses not between 1 and 10 then
    raise exception 'INVALID_USE_LIMIT';
  end if;

  raw_code := 'DMN-' || upper(encode(gen_random_bytes(5), 'hex'));
  insert into public.invite_codes(
    store_id,
    code_hash,
    role,
    max_uses,
    expires_at,
    created_by
  ) values (
    target_store_id,
    digest(raw_code, 'sha256'),
    target_role,
    allowed_uses,
    expiry,
    (select auth.uid())
  );

  return jsonb_build_object(
    'code', raw_code,
    'role', target_role,
    'max_uses', allowed_uses,
    'expires_at', expiry
  );
end;
$$;

create or replace function public.join_store_by_code(invitation_code text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  invite public.invite_codes%rowtype;
  allowed_members integer;
  active_members integer;
begin
  if (select auth.uid()) is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select * into invite
  from public.invite_codes
  where code_hash = digest(upper(trim(invitation_code)), 'sha256')
    and is_active
    and expires_at > now()
    and used_count < max_uses
  for update;

  if invite.id is null then
    raise exception 'INVITE_INVALID';
  end if;
  if not public.subscription_is_usable(invite.store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  select plans.max_members into allowed_members
  from public.subscriptions
  join public.plans on plans.id = subscriptions.plan_id
  where subscriptions.store_id = invite.store_id;

  select count(*) into active_members
  from public.store_members
  where store_id = invite.store_id and status = 'active';

  if active_members >= allowed_members and not exists (
    select 1 from public.store_members
    where store_id = invite.store_id and user_id = (select auth.uid())
  ) then
    raise exception 'SEAT_LIMIT_REACHED';
  end if;

  insert into public.store_members(store_id, user_id, role, status)
  values (invite.store_id, (select auth.uid()), invite.role, 'active')
  on conflict (store_id, user_id) do update set
    role = excluded.role,
    status = 'active',
    updated_at = now();

  update public.invite_codes
  set used_count = used_count + 1,
      is_active = used_count + 1 < max_uses
  where id = invite.id;

  insert into public.audit_logs(store_id, user_id, action, entity_type, entity_id)
  values (invite.store_id, (select auth.uid()), 'member_joined', 'member', (select auth.uid()));

  return jsonb_build_object(
    'store_id', invite.store_id,
    'user_id', (select auth.uid()),
    'role', invite.role,
    'status', 'active'
  );
end;
$$;

create or replace function public.update_store_member(
  target_store_id uuid,
  target_user_id uuid,
  target_role text,
  target_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_role text;
  existing_role text;
begin
  select role into caller_role
  from public.store_members
  where store_id = target_store_id
    and user_id = (select auth.uid())
    and status = 'active';
  select role into existing_role
  from public.store_members
  where store_id = target_store_id and user_id = target_user_id;

  if caller_role not in ('owner', 'manager') then
    raise exception 'ROLE_REQUIRED';
  end if;
  if target_user_id = (select auth.uid()) or existing_role = 'owner' then
    raise exception 'OWNER_PROTECTED';
  end if;
  if target_role not in ('manager', 'staff') or target_status not in ('active', 'suspended') then
    raise exception 'INVALID_MEMBER_UPDATE';
  end if;
  if caller_role = 'manager' and (existing_role = 'manager' or target_role = 'manager') then
    raise exception 'OWNER_REQUIRED';
  end if;

  update public.store_members
  set role = target_role, status = target_status
  where store_id = target_store_id and user_id = target_user_id;

  insert into public.audit_logs(store_id, user_id, action, entity_type, entity_id, metadata)
  values (
    target_store_id,
    (select auth.uid()),
    'member_updated',
    'member',
    target_user_id,
    jsonb_build_object('role', target_role, 'status', target_status)
  );
end;
$$;

create or replace function public.enforce_warranty_entitlement()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  warranty_limit integer;
  used_count bigint;
begin
  if not public.subscription_is_usable(new.store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  select plans.monthly_warranties into warranty_limit
  from public.subscriptions
  join public.plans on plans.id = subscriptions.plan_id
  where subscriptions.store_id = new.store_id;

  select count(*) into used_count
  from public.warranties
  where store_id = new.store_id
    and created_at >= date_trunc('month', now());

  if used_count >= warranty_limit then
    raise exception 'WARRANTY_LIMIT_REACHED';
  end if;

  if new.warranty_number is null or new.warranty_number = '' then
    new.warranty_number := 'DMN-' || to_char(now(), 'YYMM') || '-' ||
      upper(substr(replace(new.id::text, '-', ''), 1, 8));
  end if;
  return new;
end;
$$;

create trigger warranties_enforce_entitlement
before insert on public.warranties
for each row execute function public.enforce_warranty_entitlement();

create or replace function public.redeem_subscription_code(
  target_store_id uuid,
  activation_code text
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  license public.activation_codes%rowtype;
  updated_subscription_id uuid;
begin
  if not public.has_store_role(target_store_id, array['owner']) then
    raise exception 'OWNER_REQUIRED';
  end if;

  select * into license
  from public.activation_codes
  where code_hash = digest(upper(trim(activation_code)), 'sha256')
    and is_active
    and expires_at > now()
    and used_count < max_uses
  for update;

  if license.id is null then
    raise exception 'ACTIVATION_CODE_INVALID';
  end if;

  update public.subscriptions
  set plan_id = license.plan_id,
      status = 'active',
      trial_ends_at = null,
      current_period_start = now(),
      current_period_end = greatest(coalesce(current_period_end, now()), now()) +
        make_interval(days => license.duration_days),
      source = 'activation_code'
  where store_id = target_store_id
  returning id into updated_subscription_id;

  update public.activation_codes
  set used_count = used_count + 1,
      is_active = used_count + 1 < max_uses
  where id = license.id;

  insert into public.audit_logs(store_id, user_id, action, entity_type, entity_id, metadata)
  values (
    target_store_id,
    (select auth.uid()),
    'subscription_activated',
    'subscription',
    updated_subscription_id,
    jsonb_build_object('plan_id', license.plan_id, 'duration_days', license.duration_days)
  );

  return updated_subscription_id;
end;
$$;

create or replace function public.audit_business_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  row_store_id uuid;
  row_entity_id uuid;
begin
  if tg_op = 'DELETE' then
    row_store_id := old.store_id;
    row_entity_id := old.id;
  else
    row_store_id := new.store_id;
    row_entity_id := new.id;
  end if;
  insert into public.audit_logs(store_id, user_id, action, entity_type, entity_id)
  values (
    row_store_id,
    (select auth.uid()),
    lower(tg_op),
    tg_table_name,
    row_entity_id
  );
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger products_audit
after insert or update or delete on public.products
for each row execute function public.audit_business_change();
create trigger warranties_audit
after insert or update or delete on public.warranties
for each row execute function public.audit_business_change();
create trigger maintenance_audit
after insert or update or delete on public.maintenance_requests
for each row execute function public.audit_business_change();

alter table public.profiles enable row level security;
alter table public.plans enable row level security;
alter table public.stores enable row level security;
alter table public.store_members enable row level security;
alter table public.subscriptions enable row level security;
alter table public.products enable row level security;
alter table public.warranties enable row level security;
alter table public.maintenance_requests enable row level security;
alter table public.invite_codes enable row level security;
alter table public.subscription_requests enable row level security;
alter table public.activation_codes enable row level security;
alter table public.audit_logs enable row level security;

create policy profiles_select_team
on public.profiles for select to authenticated
using (id = (select auth.uid()) or public.shares_store(id));
create policy profiles_update_self
on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy plans_select_authenticated
on public.plans for select to authenticated
using (is_active);

create policy stores_select_members
on public.stores for select to authenticated
using (public.is_store_member(id));
create policy stores_update_managers
on public.stores for update to authenticated
using (public.has_store_role(id, array['owner', 'manager']))
with check (public.has_store_role(id, array['owner', 'manager']));

create policy store_members_select_members
on public.store_members for select to authenticated
using (public.is_store_member(store_id));

create policy subscriptions_select_members
on public.subscriptions for select to authenticated
using (public.is_store_member(store_id));

create policy products_select_members
on public.products for select to authenticated
using (public.is_store_member(store_id));
create policy products_insert_managers
on public.products for insert to authenticated
with check (
  public.has_store_role(store_id, array['owner', 'manager'])
  and created_by = (select auth.uid())
);
create policy products_update_managers
on public.products for update to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']))
with check (public.has_store_role(store_id, array['owner', 'manager']));
create policy products_delete_managers
on public.products for delete to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']));

create policy warranties_select_members
on public.warranties for select to authenticated
using (public.is_store_member(store_id));
create policy warranties_insert_members
on public.warranties for insert to authenticated
with check (
  public.is_store_member(store_id)
  and created_by = (select auth.uid())
);
create policy warranties_delete_managers
on public.warranties for delete to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']));

create policy maintenance_select_members
on public.maintenance_requests for select to authenticated
using (public.is_store_member(store_id));
create policy maintenance_insert_members
on public.maintenance_requests for insert to authenticated
with check (
  public.is_store_member(store_id)
  and created_by = (select auth.uid())
);
create policy maintenance_update_members
on public.maintenance_requests for update to authenticated
using (public.is_store_member(store_id))
with check (public.is_store_member(store_id));

create policy invites_select_managers
on public.invite_codes for select to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']));

create policy subscription_requests_select_owner
on public.subscription_requests for select to authenticated
using (public.has_store_role(store_id, array['owner']));
create policy subscription_requests_insert_owner
on public.subscription_requests for insert to authenticated
with check (
  public.has_store_role(store_id, array['owner'])
  and requested_by = (select auth.uid())
);

create policy audit_logs_select_managers
on public.audit_logs for select to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']));

create view public.store_member_directory
with (security_invoker = true)
as
select
  members.store_id,
  members.user_id,
  members.role,
  members.status,
  members.joined_at,
  profiles.full_name,
  profiles.email
from public.store_members members
join public.profiles profiles on profiles.id = members.user_id;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.plans from anon, authenticated;
revoke all on table public.stores from anon, authenticated;
revoke all on table public.store_members from anon, authenticated;
revoke all on table public.subscriptions from anon, authenticated;
revoke all on table public.products from anon, authenticated;
revoke all on table public.warranties from anon, authenticated;
revoke all on table public.maintenance_requests from anon, authenticated;
revoke all on table public.invite_codes from anon, authenticated;
revoke all on table public.subscription_requests from anon, authenticated;
revoke all on table public.activation_codes from anon, authenticated;
revoke all on table public.audit_logs from anon, authenticated;

grant select, update on table public.profiles to authenticated;
grant select on table public.plans to authenticated;
grant select, update on table public.stores to authenticated;
grant select on table public.store_members to authenticated;
grant select on table public.subscriptions to authenticated;
grant select, insert, update, delete on table public.products to authenticated;
grant select, insert, delete on table public.warranties to authenticated;
grant select, insert, update on table public.maintenance_requests to authenticated;
grant select on table public.invite_codes to authenticated;
grant select, insert on table public.subscription_requests to authenticated;
grant select on table public.audit_logs to authenticated;
grant select on table public.store_member_directory to authenticated;

revoke all on function public.is_store_member(uuid) from public;
revoke all on function public.has_store_role(uuid, text[]) from public;
revoke all on function public.shares_store(uuid) from public;
revoke all on function public.subscription_is_usable(uuid) from public;
revoke all on function public.current_warranty_usage(uuid) from public;
revoke all on function public.create_store_with_trial(text, text, text, text) from public;
revoke all on function public.create_store_invite(uuid, text, integer) from public;
revoke all on function public.join_store_by_code(text) from public;
revoke all on function public.update_store_member(uuid, uuid, text, text) from public;
revoke all on function public.redeem_subscription_code(uuid, text) from public;

grant execute on function public.is_store_member(uuid) to authenticated;
grant execute on function public.has_store_role(uuid, text[]) to authenticated;
grant execute on function public.shares_store(uuid) to authenticated;
grant execute on function public.subscription_is_usable(uuid) to authenticated;
grant execute on function public.current_warranty_usage(uuid) to authenticated;
grant execute on function public.create_store_with_trial(text, text, text, text) to authenticated;
grant execute on function public.create_store_invite(uuid, text, integer) to authenticated;
grant execute on function public.join_store_by_code(text) to authenticated;
grant execute on function public.update_store_member(uuid, uuid, text, text) to authenticated;
grant execute on function public.redeem_subscription_code(uuid, text) to authenticated;
