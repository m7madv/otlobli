-- Damanak 3.0: store finance profile, branches, customers and invoice totals.

alter table public.stores
  add column if not exists currency_code text not null default 'SAR',
  add column if not exists tax_rate numeric(5, 2) not null default 15,
  add column if not exists prices_include_tax boolean not null default true,
  add column if not exists tax_number text not null default '',
  add column if not exists commercial_registration text not null default '',
  add column if not exists address text not null default '',
  add column if not exists invoice_prefix text not null default 'INV',
  add column if not exists default_warranty_months integer not null default 12;

alter table public.stores drop constraint if exists stores_country_code_check;
alter table public.stores add constraint stores_country_code_check
  check (country_code in ('SA', 'AE', 'KW', 'QA', 'BH', 'OM', 'SY'));
alter table public.stores add constraint stores_currency_code_check
  check (currency_code in ('SAR', 'AED', 'KWD', 'QAR', 'BHD', 'OMR', 'USD', 'SYP'));
alter table public.stores add constraint stores_tax_rate_check
  check (tax_rate between 0 and 100);
alter table public.stores add constraint stores_invoice_prefix_check
  check (invoice_prefix ~ '^[A-Z0-9]{2,8}$');
alter table public.stores add constraint stores_default_warranty_months_check
  check (default_warranty_months between 1 and 120);

update public.stores
set currency_code = case country_code
  when 'AE' then 'AED'
  when 'KW' then 'KWD'
  when 'QA' then 'QAR'
  when 'BH' then 'BHD'
  when 'OM' then 'OMR'
  when 'SY' then 'SYP'
  else 'SAR'
end
where currency_code = 'SAR' and country_code <> 'SA';

alter table public.products
  add column if not exists category text not null default '';

create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 120),
  code text not null check (code ~ '^[A-Z0-9-]{2,12}$'),
  city text not null default '',
  address text not null default '',
  phone text not null default '',
  is_main boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(store_id, code)
);

create unique index if not exists branches_one_main_per_store
  on public.branches(store_id)
  where is_main and is_active;

insert into public.branches(store_id, name, code, city, address, phone, is_main)
select id, 'الفرع الرئيسي', 'MAIN', city, address, phone, true
from public.stores
on conflict (store_id, code) do nothing;

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 160),
  phone text not null check (char_length(trim(phone)) between 7 and 30),
  email text,
  notes text not null default '',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(store_id, phone)
);

create index if not exists customers_store_name_idx
  on public.customers(store_id, name);

insert into public.customers(store_id, name, phone, created_by, created_at, updated_at)
select distinct on (store_id, customer_phone)
  store_id,
  customer_name,
  customer_phone,
  created_by,
  created_at,
  updated_at
from public.warranties
order by store_id, customer_phone, created_at desc
on conflict (store_id, phone) do nothing;

alter table public.warranties
  add column if not exists customer_id uuid references public.customers(id) on delete restrict,
  add column if not exists branch_id uuid references public.branches(id) on delete set null,
  add column if not exists invoice_number text,
  add column if not exists sale_subtotal numeric(14, 3) not null default 0,
  add column if not exists discount_amount numeric(14, 3) not null default 0,
  add column if not exists tax_amount numeric(14, 3) not null default 0,
  add column if not exists sale_total numeric(14, 3) not null default 0,
  add column if not exists tax_rate numeric(5, 2) not null default 0,
  add column if not exists currency_code text not null default 'SAR',
  add column if not exists payment_method text not null default 'cash';

update public.warranties warranties
set customer_id = customers.id
from public.customers customers
where warranties.customer_id is null
  and customers.store_id = warranties.store_id
  and customers.phone = warranties.customer_phone;

update public.warranties warranties
set branch_id = branches.id
from public.branches branches
where warranties.branch_id is null
  and branches.store_id = warranties.store_id
  and branches.is_main;

update public.warranties warranties
set currency_code = stores.currency_code,
    tax_rate = stores.tax_rate
from public.stores stores
where stores.id = warranties.store_id;

alter table public.warranties alter column customer_id set not null;
alter table public.warranties add constraint warranties_amounts_check check (
  sale_subtotal >= 0 and
  discount_amount >= 0 and
  discount_amount <= sale_subtotal and
  tax_amount >= 0 and
  sale_total >= 0
);
alter table public.warranties add constraint warranties_tax_rate_check
  check (tax_rate between 0 and 100);
alter table public.warranties add constraint warranties_currency_code_check
  check (currency_code in ('SAR', 'AED', 'KWD', 'QAR', 'BHD', 'OMR', 'USD', 'SYP'));
alter table public.warranties add constraint warranties_payment_method_check
  check (payment_method in ('cash', 'card', 'bank_transfer', 'digital_wallet', 'other'));

create unique index if not exists warranties_store_invoice_unique
  on public.warranties(store_id, invoice_number)
  where invoice_number is not null and invoice_number <> '';
create index if not exists warranties_store_customer_idx
  on public.warranties(store_id, customer_id, created_at desc);
create index if not exists warranties_store_branch_idx
  on public.warranties(store_id, branch_id, created_at desc);

create or replace function public.set_store_financial_defaults()
returns trigger
language plpgsql
as $$
begin
  if new.currency_code is null or new.currency_code = '' or
      (tg_op = 'INSERT' and new.currency_code = 'SAR' and new.country_code <> 'SA') then
    new.currency_code := case new.country_code
      when 'AE' then 'AED'
      when 'KW' then 'KWD'
      when 'QA' then 'QAR'
      when 'BH' then 'BHD'
      when 'OM' then 'OMR'
      when 'SY' then 'SYP'
      else 'SAR'
    end;
  end if;
  new.invoice_prefix := upper(trim(coalesce(new.invoice_prefix, 'INV')));
  return new;
end;
$$;

drop trigger if exists stores_financial_defaults on public.stores;
create trigger stores_financial_defaults
before insert or update on public.stores
for each row execute function public.set_store_financial_defaults();

create or replace function public.create_default_store_branch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.branches(store_id, name, code, city, address, phone, is_main)
  values (new.id, 'الفرع الرئيسي', 'MAIN', new.city, new.address, new.phone, true)
  on conflict (store_id, code) do nothing;
  return new;
end;
$$;

drop trigger if exists stores_create_default_branch on public.stores;
create trigger stores_create_default_branch
after insert on public.stores
for each row execute function public.create_default_store_branch();

create or replace function public.set_warranty_invoice_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  prefix text;
begin
  if new.invoice_number is null or trim(new.invoice_number) = '' then
    select invoice_prefix into prefix from public.stores where id = new.store_id;
    new.invoice_number := coalesce(nullif(prefix, ''), 'INV') || '-' ||
      to_char(now(), 'YYMMDD') || '-' ||
      upper(substr(replace(new.id::text, '-', ''), 1, 6));
  else
    new.invoice_number := upper(trim(new.invoice_number));
  end if;
  return new;
end;
$$;

drop trigger if exists warranties_set_invoice_number on public.warranties;
create trigger warranties_set_invoice_number
before insert on public.warranties
for each row execute function public.set_warranty_invoice_number();

create trigger branches_updated_at
before update on public.branches
for each row execute function public.set_updated_at();
create trigger customers_updated_at
before update on public.customers
for each row execute function public.set_updated_at();

create trigger branches_audit
after insert or update or delete on public.branches
for each row execute function public.audit_business_change();
create trigger customers_audit
after insert or update or delete on public.customers
for each row execute function public.audit_business_change();

alter table public.branches enable row level security;
alter table public.customers enable row level security;

create policy branches_select_members
on public.branches for select to authenticated
using (public.is_store_member(store_id));
create policy branches_insert_managers
on public.branches for insert to authenticated
with check (public.has_store_role(store_id, array['owner', 'manager']));
create policy branches_update_managers
on public.branches for update to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']))
with check (public.has_store_role(store_id, array['owner', 'manager']));
create policy branches_delete_managers
on public.branches for delete to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']));

create policy customers_select_members
on public.customers for select to authenticated
using (public.is_store_member(store_id));
create policy customers_insert_members
on public.customers for insert to authenticated
with check (
  public.is_store_member(store_id)
  and created_by = (select auth.uid())
);
create policy customers_update_members
on public.customers for update to authenticated
using (public.is_store_member(store_id))
with check (public.is_store_member(store_id));
create policy customers_delete_managers
on public.customers for delete to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']));

revoke all on table public.branches from anon, authenticated;
revoke all on table public.customers from anon, authenticated;
grant select, insert, update, delete on table public.branches to authenticated;
grant select, insert, update, delete on table public.customers to authenticated;
