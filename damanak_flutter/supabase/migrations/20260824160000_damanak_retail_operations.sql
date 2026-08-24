-- Damanak 4.0: multi-branch inventory, POS, returns, registers and purchasing.

alter table public.branches
  add column if not exists email text,
  add column if not exists manager_name text not null default '',
  add column if not exists receipt_prefix text not null default 'POS',
  add column if not exists timezone text not null default 'Asia/Riyadh',
  add column if not exists opens_at time not null default '09:00',
  add column if not exists closes_at time not null default '23:00',
  add column if not exists branch_type text not null default 'retail',
  add column if not exists accepts_sales boolean not null default true,
  add column if not exists handles_service boolean not null default true;

alter table public.products
  add column if not exists cost_price numeric(14, 3),
  add column if not exists track_inventory boolean not null default true,
  add column if not exists is_serialized boolean not null default false,
  add column if not exists reorder_point numeric(14, 3) not null default 2;

drop index if exists public.warranties_store_invoice_unique;
create index if not exists warranties_store_invoice_idx
  on public.warranties(store_id, invoice_number);

alter table public.warranties
  add column if not exists sale_id uuid,
  add column if not exists sale_line_id uuid,
  add column if not exists voided_at timestamptz;

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
    select count(*) from public.warranties
    where store_id = target_store_id
      and voided_at is null
      and created_at >= date_trunc('month', now())
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
  select count(*) into used_count from public.warranties
  where store_id = new.store_id and voided_at is null
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

create table public.inventory_levels (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  on_hand numeric(14, 3) not null default 0 check (on_hand >= 0),
  reserved numeric(14, 3) not null default 0 check (reserved >= 0 and reserved <= on_hand),
  reorder_point numeric(14, 3) not null default 0 check (reorder_point >= 0),
  average_cost numeric(14, 3) not null default 0 check (average_cost >= 0),
  updated_at timestamptz not null default now(),
  unique(branch_id, product_id)
);

create index inventory_levels_store_branch_idx
  on public.inventory_levels(store_id, branch_id, product_id);

create table public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete restrict,
  movement_type text not null check (movement_type in (
    'opening', 'purchase', 'sale', 'return_in',
    'transfer_out', 'transfer_in', 'adjustment'
  )),
  quantity numeric(14, 3) not null check (quantity <> 0),
  unit_cost numeric(14, 3) not null default 0 check (unit_cost >= 0),
  reference_type text not null default '',
  reference_id uuid,
  note text not null default '',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index stock_movements_store_created_idx
  on public.stock_movements(store_id, created_at desc);
create index stock_movements_product_branch_idx
  on public.stock_movements(product_id, branch_id, created_at desc);

create table public.sales (
  id uuid primary key default gen_random_uuid(),
  sequence_number bigint generated always as identity,
  store_id uuid not null references public.stores(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete restrict,
  customer_id uuid references public.customers(id) on delete set null,
  customer_name text not null default 'عميل نقدي',
  customer_phone text not null default '',
  invoice_number text not null,
  status text not null default 'completed' check (
    status in ('completed', 'partially_returned', 'returned', 'voided')
  ),
  subtotal numeric(14, 3) not null check (subtotal >= 0),
  discount_amount numeric(14, 3) not null default 0 check (discount_amount >= 0),
  tax_amount numeric(14, 3) not null default 0 check (tax_amount >= 0),
  total numeric(14, 3) not null check (total >= 0),
  refunded_amount numeric(14, 3) not null default 0 check (refunded_amount >= 0),
  currency_code text not null,
  tax_rate numeric(5, 2) not null default 0,
  prices_include_tax boolean not null default true,
  notes text not null default '',
  cashier_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(store_id, invoice_number)
);

create index sales_store_created_idx on public.sales(store_id, created_at desc);
create index sales_branch_created_idx on public.sales(branch_id, created_at desc);

create table public.sale_lines (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  product_name text not null,
  sku text not null default '',
  barcode text not null default '',
  quantity numeric(14, 3) not null check (quantity > 0),
  returned_quantity numeric(14, 3) not null default 0 check (
    returned_quantity >= 0 and returned_quantity <= quantity
  ),
  unit_price numeric(14, 3) not null check (unit_price >= 0),
  unit_cost numeric(14, 3) not null default 0 check (unit_cost >= 0),
  discount_amount numeric(14, 3) not null default 0 check (discount_amount >= 0),
  tax_amount numeric(14, 3) not null default 0 check (tax_amount >= 0),
  line_total numeric(14, 3) not null check (line_total >= 0),
  warranty_months integer not null default 0 check (warranty_months between 0 and 120),
  serial_numbers text[] not null default '{}'
);

create index sale_lines_sale_idx on public.sale_lines(sale_id);

create table public.sale_payments (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  payment_method text not null check (
    payment_method in ('cash', 'card', 'bank_transfer', 'digital_wallet', 'other')
  ),
  amount numeric(14, 3) not null check (amount > 0),
  reference text not null default '',
  created_at timestamptz not null default now()
);

create index sale_payments_sale_idx on public.sale_payments(sale_id);

create table public.sale_returns (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete restrict,
  store_id uuid not null references public.stores(id) on delete cascade,
  refund_method text not null check (
    refund_method in ('cash', 'card', 'bank_transfer', 'digital_wallet', 'other')
  ),
  refund_amount numeric(14, 3) not null check (refund_amount > 0),
  reason text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.sale_return_lines (
  id uuid primary key default gen_random_uuid(),
  return_id uuid not null references public.sale_returns(id) on delete cascade,
  sale_line_id uuid not null references public.sale_lines(id) on delete restrict,
  quantity numeric(14, 3) not null check (quantity > 0),
  refund_amount numeric(14, 3) not null check (refund_amount >= 0)
);

create table public.register_sessions (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete restrict,
  opened_by uuid references auth.users(id) on delete set null,
  closed_by uuid references auth.users(id) on delete set null,
  opening_cash numeric(14, 3) not null default 0 check (opening_cash >= 0),
  cash_sales numeric(14, 3) not null default 0 check (cash_sales >= 0),
  cash_refunds numeric(14, 3) not null default 0 check (cash_refunds >= 0),
  cash_in numeric(14, 3) not null default 0 check (cash_in >= 0),
  cash_out numeric(14, 3) not null default 0 check (cash_out >= 0),
  closing_cash numeric(14, 3) not null default 0 check (closing_cash >= 0),
  status text not null default 'open' check (status in ('open', 'closed')),
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  notes text not null default ''
);

create unique index register_sessions_one_open_per_branch
  on public.register_sessions(branch_id) where status = 'open';
create index register_sessions_store_opened_idx
  on public.register_sessions(store_id, opened_at desc);

create table public.suppliers (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 160),
  contact_name text not null default '',
  phone text not null default '',
  email text,
  tax_number text not null default '',
  address text not null default '',
  notes text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index suppliers_store_name_idx on public.suppliers(store_id, name);

create table public.purchase_orders (
  id uuid primary key default gen_random_uuid(),
  sequence_number bigint generated always as identity,
  store_id uuid not null references public.stores(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete restrict,
  supplier_id uuid not null references public.suppliers(id) on delete restrict,
  order_number text not null,
  status text not null default 'ordered' check (
    status in ('draft', 'ordered', 'partially_received', 'received', 'cancelled')
  ),
  expected_at timestamptz,
  notes text not null default '',
  total_cost numeric(14, 3) not null default 0 check (total_cost >= 0),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(store_id, order_number)
);

create index purchase_orders_store_created_idx
  on public.purchase_orders(store_id, created_at desc);

create table public.purchase_order_lines (
  id uuid primary key default gen_random_uuid(),
  purchase_order_id uuid not null references public.purchase_orders(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  product_name text not null,
  quantity numeric(14, 3) not null check (quantity > 0),
  received_quantity numeric(14, 3) not null default 0 check (
    received_quantity >= 0 and received_quantity <= quantity
  ),
  unit_cost numeric(14, 3) not null check (unit_cost >= 0)
);

create index purchase_order_lines_order_idx
  on public.purchase_order_lines(purchase_order_id);

alter table public.warranties
  add constraint warranties_sale_fk foreign key (sale_id)
    references public.sales(id) on delete set null,
  add constraint warranties_sale_line_fk foreign key (sale_line_id)
    references public.sale_lines(id) on delete set null;

create or replace function public.seed_inventory_for_product()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.inventory_levels(
    store_id, branch_id, product_id, reorder_point, average_cost
  )
  select new.store_id, branches.id, new.id, new.reorder_point,
         coalesce(new.cost_price, 0)
  from public.branches
  where branches.store_id = new.store_id and branches.is_active
  on conflict (branch_id, product_id) do nothing;
  return new;
end;
$$;

create trigger products_seed_inventory
after insert on public.products
for each row execute function public.seed_inventory_for_product();

create or replace function public.seed_inventory_for_branch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.inventory_levels(
    store_id, branch_id, product_id, reorder_point, average_cost
  )
  select new.store_id, new.id, products.id, products.reorder_point,
         coalesce(products.cost_price, 0)
  from public.products
  where products.store_id = new.store_id and products.is_active
  on conflict (branch_id, product_id) do nothing;
  return new;
end;
$$;

create trigger branches_seed_inventory
after insert on public.branches
for each row execute function public.seed_inventory_for_branch();

insert into public.inventory_levels(
  store_id, branch_id, product_id, reorder_point, average_cost
)
select products.store_id, branches.id, products.id, products.reorder_point,
       coalesce(products.cost_price, 0)
from public.products
join public.branches on branches.store_id = products.store_id
where products.is_active and branches.is_active
on conflict (branch_id, product_id) do nothing;

create or replace function public.adjust_inventory(
  target_store_id uuid,
  target_branch_id uuid,
  target_product_id uuid,
  new_quantity numeric,
  target_unit_cost numeric,
  target_note text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  level public.inventory_levels%rowtype;
  old_quantity numeric;
begin
  if not public.has_store_role(target_store_id, array['owner', 'manager']) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if new_quantity < 0 or target_unit_cost < 0 then
    raise exception 'INVALID_INVENTORY_VALUE';
  end if;
  if not exists (
    select 1 from public.branches
    where id = target_branch_id and store_id = target_store_id and is_active
  ) or not exists (
    select 1 from public.products
    where id = target_product_id and store_id = target_store_id and is_active
  ) then
    raise exception 'INVENTORY_SCOPE_INVALID';
  end if;

  insert into public.inventory_levels(
    store_id, branch_id, product_id, on_hand, average_cost, reorder_point
  )
  select target_store_id, target_branch_id, target_product_id, 0,
         target_unit_cost, reorder_point
  from public.products where id = target_product_id
  on conflict (branch_id, product_id) do nothing;

  select * into level from public.inventory_levels
  where branch_id = target_branch_id and product_id = target_product_id
  for update;
  old_quantity := level.on_hand;

  update public.inventory_levels
  set on_hand = new_quantity,
      average_cost = target_unit_cost,
      updated_at = now()
  where id = level.id
  returning * into level;

  if new_quantity <> old_quantity then
    insert into public.stock_movements(
      store_id, branch_id, product_id, movement_type, quantity,
      unit_cost, reference_type, note, created_by
    ) values (
      target_store_id, target_branch_id, target_product_id, 'adjustment',
      new_quantity - old_quantity, target_unit_cost, 'manual_adjustment',
      coalesce(target_note, ''), auth.uid()
    );
  end if;
  return to_jsonb(level);
end;
$$;

create or replace function public.transfer_inventory(
  target_store_id uuid,
  target_product_id uuid,
  source_branch_id uuid,
  destination_branch_id uuid,
  target_quantity numeric,
  target_note text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  source_level public.inventory_levels%rowtype;
  transfer_id uuid := gen_random_uuid();
begin
  if not public.has_store_role(target_store_id, array['owner', 'manager']) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if target_quantity <= 0 or source_branch_id = destination_branch_id then
    raise exception 'INVALID_TRANSFER';
  end if;
  if (select count(*) from public.branches where store_id = target_store_id
      and id in (source_branch_id, destination_branch_id) and is_active) <> 2 then
    raise exception 'BRANCH_SCOPE_INVALID';
  end if;

  select * into source_level from public.inventory_levels
  where branch_id = source_branch_id and product_id = target_product_id
  for update;
  if not found or source_level.on_hand - source_level.reserved < target_quantity then
    raise exception 'INSUFFICIENT_STOCK';
  end if;

  update public.inventory_levels
  set on_hand = on_hand - target_quantity, updated_at = now()
  where id = source_level.id;
  insert into public.inventory_levels(
    store_id, branch_id, product_id, on_hand, reorder_point, average_cost
  ) values (
    target_store_id, destination_branch_id, target_product_id, target_quantity,
    source_level.reorder_point, source_level.average_cost
  )
  on conflict (branch_id, product_id) do update
  set on_hand = public.inventory_levels.on_hand + excluded.on_hand,
      average_cost = excluded.average_cost,
      updated_at = now();

  insert into public.stock_movements(
    store_id, branch_id, product_id, movement_type, quantity, unit_cost,
    reference_type, reference_id, note, created_by
  ) values
    (target_store_id, source_branch_id, target_product_id, 'transfer_out',
     -target_quantity, source_level.average_cost, 'stock_transfer', transfer_id,
     coalesce(target_note, ''), auth.uid()),
    (target_store_id, destination_branch_id, target_product_id, 'transfer_in',
     target_quantity, source_level.average_cost, 'stock_transfer', transfer_id,
     coalesce(target_note, ''), auth.uid());
end;
$$;

create or replace function public.create_sale(
  target_store_id uuid,
  target_branch_id uuid,
  target_customer_id uuid,
  target_customer_name text,
  target_customer_phone text,
  sale_lines_input jsonb,
  sale_payments_input jsonb,
  order_discount numeric,
  target_notes text
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  store_row public.stores%rowtype;
  branch_row public.branches%rowtype;
  product_row public.products%rowtype;
  inventory_row public.inventory_levels%rowtype;
  created_sale public.sales%rowtype;
  created_line public.sale_lines%rowtype;
  input_line jsonb;
  input_payment jsonb;
  serials text[];
  quantity numeric;
  unit_price numeric;
  line_discount numeric;
  gross numeric;
  discounted numeric;
  line_tax numeric;
  line_total numeric;
  subtotal_value numeric := 0;
  line_discounts numeric := 0;
  tax_value numeric := 0;
  total_value numeric := 0;
  payment_value numeric := 0;
  unit_number integer;
  invoice_value text;
  resolved_customer_id uuid := target_customer_id;
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if jsonb_array_length(coalesce(sale_lines_input, '[]'::jsonb)) = 0 then
    raise exception 'EMPTY_SALE';
  end if;
  select * into store_row from public.stores where id = target_store_id;
  select * into branch_row from public.branches
  where id = target_branch_id and store_id = target_store_id and is_active
    and accepts_sales;
  if not found then raise exception 'BRANCH_SALES_DISABLED'; end if;

  if resolved_customer_id is not null and not exists (
    select 1 from public.customers
    where id = resolved_customer_id and store_id = target_store_id
  ) then
    raise exception 'CUSTOMER_SCOPE_INVALID';
  end if;
  if resolved_customer_id is null and length(trim(coalesce(target_customer_phone, ''))) >= 7 then
    insert into public.customers(store_id, name, phone, created_by)
    values (
      target_store_id,
      coalesce(nullif(trim(target_customer_name), ''), 'عميل المتجر'),
      trim(target_customer_phone), auth.uid()
    )
    on conflict (store_id, phone) do update set
      name = excluded.name, updated_at = now()
    returning id into resolved_customer_id;
  end if;

  for input_line in select * from jsonb_array_elements(sale_lines_input)
  loop
    quantity := (input_line->>'quantity')::numeric;
    unit_price := (input_line->>'unit_price')::numeric;
    line_discount := coalesce((input_line->>'discount_amount')::numeric, 0);
    if quantity <= 0 or unit_price < 0 or line_discount < 0
       or line_discount > quantity * unit_price then
      raise exception 'INVALID_SALE_LINE';
    end if;
    select * into product_row from public.products
    where id = (input_line->>'product_id')::uuid
      and store_id = target_store_id and is_active;
    if not found then raise exception 'PRODUCT_NOT_FOUND'; end if;
    serials := coalesce(array(
      select jsonb_array_elements_text(coalesce(input_line->'serial_numbers', '[]'::jsonb))
    ), array[]::text[]);
    if product_row.is_serialized and
       (quantity <> trunc(quantity) or cardinality(serials) <> quantity::integer) then
      raise exception 'SERIAL_NUMBERS_REQUIRED';
    end if;
    if product_row.track_inventory then
      select * into inventory_row from public.inventory_levels
      where branch_id = target_branch_id and product_id = product_row.id
      for update;
      if not found or inventory_row.on_hand - inventory_row.reserved < quantity then
        raise exception 'INSUFFICIENT_STOCK';
      end if;
    end if;
    subtotal_value := subtotal_value + quantity * unit_price;
    line_discounts := line_discounts + line_discount;
  end loop;

  if order_discount < 0 or order_discount > subtotal_value - line_discounts then
    raise exception 'INVALID_DISCOUNT';
  end if;
  discounted := subtotal_value - line_discounts - order_discount;
  if store_row.prices_include_tax then
    tax_value := round(discounted * store_row.tax_rate / (100 + store_row.tax_rate), 3);
    total_value := round(discounted, 3);
  else
    tax_value := round(discounted * store_row.tax_rate / 100, 3);
    total_value := round(discounted + tax_value, 3);
  end if;

  for input_payment in select * from jsonb_array_elements(coalesce(sale_payments_input, '[]'::jsonb))
  loop
    if (input_payment->>'amount')::numeric <= 0 then
      raise exception 'INVALID_PAYMENT';
    end if;
    payment_value := payment_value + (input_payment->>'amount')::numeric;
  end loop;
  if abs(payment_value - total_value) > 0.01 then
    raise exception 'PAYMENT_TOTAL_MISMATCH';
  end if;

  insert into public.sales(
    store_id, branch_id, customer_id, customer_name, customer_phone,
    invoice_number, subtotal, discount_amount, tax_amount, total,
    currency_code, tax_rate, prices_include_tax, notes, cashier_id
  ) values (
    target_store_id, target_branch_id, resolved_customer_id,
    coalesce(nullif(trim(target_customer_name), ''), 'عميل نقدي'),
    coalesce(trim(target_customer_phone), ''), 'PENDING', subtotal_value,
    line_discounts + order_discount, tax_value, total_value,
    store_row.currency_code, store_row.tax_rate, store_row.prices_include_tax,
    coalesce(target_notes, ''), auth.uid()
  ) returning * into created_sale;
  invoice_value := branch_row.receipt_prefix || '-' ||
    to_char(now(), 'YYMM') || '-' || lpad(created_sale.sequence_number::text, 6, '0');
  update public.sales set invoice_number = invoice_value where id = created_sale.id;

  for input_line in select * from jsonb_array_elements(sale_lines_input)
  loop
    quantity := (input_line->>'quantity')::numeric;
    unit_price := (input_line->>'unit_price')::numeric;
    line_discount := coalesce((input_line->>'discount_amount')::numeric, 0);
    select * into product_row from public.products
    where id = (input_line->>'product_id')::uuid;
    serials := coalesce(array(
      select jsonb_array_elements_text(coalesce(input_line->'serial_numbers', '[]'::jsonb))
    ), array[]::text[]);
    gross := quantity * unit_price;
    line_discount := line_discount + case when subtotal_value - line_discounts = 0 then 0
      else order_discount * (gross - line_discount) / (subtotal_value - line_discounts) end;
    discounted := gross - line_discount;
    if store_row.prices_include_tax then
      line_tax := round(discounted * store_row.tax_rate / (100 + store_row.tax_rate), 3);
      line_total := round(discounted, 3);
    else
      line_tax := round(discounted * store_row.tax_rate / 100, 3);
      line_total := round(discounted + line_tax, 3);
    end if;
    select * into inventory_row from public.inventory_levels
      where branch_id = target_branch_id and product_id = product_row.id;

    insert into public.sale_lines(
      sale_id, store_id, product_id, product_name, sku, barcode, quantity,
      unit_price, unit_cost, discount_amount, tax_amount, line_total,
      warranty_months, serial_numbers
    ) values (
      created_sale.id, target_store_id, product_row.id, product_row.name,
      coalesce(product_row.sku, ''), coalesce(product_row.barcode, ''), quantity,
      unit_price, coalesce(inventory_row.average_cost, product_row.cost_price, 0),
      round(line_discount, 3), line_tax, line_total,
      product_row.warranty_months, serials
    ) returning * into created_line;

    if product_row.track_inventory then
      update public.inventory_levels
      set on_hand = on_hand - quantity, updated_at = now()
      where branch_id = target_branch_id and product_id = product_row.id;
      insert into public.stock_movements(
        store_id, branch_id, product_id, movement_type, quantity, unit_cost,
        reference_type, reference_id, note, created_by
      ) values (
        target_store_id, target_branch_id, product_row.id, 'sale', -quantity,
        coalesce(inventory_row.average_cost, 0), 'sale', created_sale.id,
        invoice_value, auth.uid()
      );
    end if;

    if product_row.warranty_months > 0 and resolved_customer_id is not null then
      for unit_number in 1..quantity::integer loop
        insert into public.warranties(
          warranty_number, store_id, product_id, customer_id, branch_id,
          customer_name, customer_phone, product_name, barcode, serial_number,
          purchase_date, expiry_date, notes, created_by, invoice_number,
          sale_subtotal, discount_amount, tax_amount, sale_total, tax_rate,
          currency_code, payment_method, sale_id, sale_line_id
        ) values (
          '', target_store_id, product_row.id, resolved_customer_id, target_branch_id,
          coalesce(nullif(trim(target_customer_name), ''), 'عميل المتجر'),
          trim(target_customer_phone), product_row.name, product_row.barcode,
          coalesce(serials[unit_number], ''), current_date,
          (current_date + make_interval(months => product_row.warranty_months))::date,
          coalesce(target_notes, ''), auth.uid(), invoice_value,
          unit_price, line_discount / quantity, line_tax / quantity,
          line_total / quantity, store_row.tax_rate, store_row.currency_code,
          coalesce(sale_payments_input->0->>'payment_method', 'cash'),
          created_sale.id, created_line.id
        );
      end loop;
    end if;
  end loop;

  for input_payment in select * from jsonb_array_elements(sale_payments_input)
  loop
    insert into public.sale_payments(
      sale_id, store_id, payment_method, amount, reference
    ) values (
      created_sale.id, target_store_id, input_payment->>'payment_method',
      (input_payment->>'amount')::numeric,
      coalesce(input_payment->>'reference', '')
    );
  end loop;
  return created_sale.id;
end;
$$;

create or replace function public.return_sale(
  target_store_id uuid,
  target_sale_id uuid,
  returned_lines jsonb,
  refund_method text,
  return_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  sale_row public.sales%rowtype;
  line_row public.sale_lines%rowtype;
  return_id uuid;
  item jsonb;
  return_quantity numeric;
  refund_value numeric := 0;
  line_refund numeric;
  everything_returned boolean;
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if refund_method not in ('cash', 'card', 'bank_transfer', 'digital_wallet', 'other') then
    raise exception 'INVALID_REFUND_METHOD';
  end if;
  select * into sale_row from public.sales
  where id = target_sale_id and store_id = target_store_id
    and status not in ('returned', 'voided') for update;
  if not found then raise exception 'SALE_NOT_RETURNABLE'; end if;

  insert into public.sale_returns(
    sale_id, store_id, refund_method, refund_amount, reason, created_by
  ) values (
    target_sale_id, target_store_id, refund_method, 0,
    coalesce(nullif(trim(return_reason), ''), 'مرتجع عميل'), auth.uid()
  ) returning id into return_id;

  for item in select * from jsonb_array_elements(coalesce(returned_lines, '[]'::jsonb))
  loop
    return_quantity := (item->>'quantity')::numeric;
    select * into line_row from public.sale_lines
    where id = (item->>'sale_line_id')::uuid and sale_id = target_sale_id
    for update;
    if not found or return_quantity <= 0
       or line_row.returned_quantity + return_quantity > line_row.quantity then
      raise exception 'INVALID_RETURN_QUANTITY';
    end if;
    line_refund := round(line_row.line_total / line_row.quantity * return_quantity, 3);
    refund_value := refund_value + line_refund;
    update public.sale_lines
    set returned_quantity = returned_quantity + return_quantity
    where id = line_row.id;
    update public.inventory_levels
    set on_hand = on_hand + return_quantity, updated_at = now()
    where branch_id = sale_row.branch_id and product_id = line_row.product_id;
    insert into public.stock_movements(
      store_id, branch_id, product_id, movement_type, quantity, unit_cost,
      reference_type, reference_id, note, created_by
    ) values (
      target_store_id, sale_row.branch_id, line_row.product_id, 'return_in',
      return_quantity, line_row.unit_cost, 'sale_return', return_id,
      coalesce(return_reason, ''), auth.uid()
    );
    insert into public.sale_return_lines(
      return_id, sale_line_id, quantity, refund_amount
    ) values (return_id, line_row.id, return_quantity, line_refund);

    if line_row.returned_quantity + return_quantity >= line_row.quantity then
      update public.warranties set voided_at = now()
      where sale_line_id = line_row.id and voided_at is null;
    end if;
  end loop;
  if refund_value <= 0 then raise exception 'EMPTY_RETURN'; end if;

  update public.sale_returns set refund_amount = refund_value where id = return_id;
  select bool_and(returned_quantity >= quantity) into everything_returned
  from public.sale_lines where sale_id = target_sale_id;
  update public.sales
  set refunded_amount = refunded_amount + refund_value,
      status = case when everything_returned then 'returned' else 'partially_returned' end,
      updated_at = now()
  where id = target_sale_id;
end;
$$;

create or replace function public.open_register(
  target_store_id uuid,
  target_branch_id uuid,
  target_opening_cash numeric,
  target_notes text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare session_row public.register_sessions%rowtype;
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if target_opening_cash < 0 or not exists (
    select 1 from public.branches where id = target_branch_id
      and store_id = target_store_id and accepts_sales and is_active
  ) then raise exception 'INVALID_REGISTER'; end if;
  insert into public.register_sessions(
    store_id, branch_id, opened_by, opening_cash, notes
  ) values (
    target_store_id, target_branch_id, auth.uid(), target_opening_cash,
    coalesce(target_notes, '')
  ) returning * into session_row;
  return to_jsonb(session_row);
exception when unique_violation then
  raise exception 'REGISTER_ALREADY_OPEN';
end;
$$;

create or replace function public.close_register(
  target_session_id uuid,
  target_closing_cash numeric,
  target_notes text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare session_row public.register_sessions%rowtype;
begin
  select * into session_row from public.register_sessions
  where id = target_session_id and status = 'open' for update;
  if not found or not public.is_store_member(session_row.store_id) then
    raise exception 'REGISTER_NOT_FOUND';
  end if;
  if target_closing_cash < 0 then raise exception 'INVALID_CLOSING_CASH'; end if;
  select coalesce(sum(payments.amount), 0) into session_row.cash_sales
  from public.sale_payments payments
  join public.sales sales on sales.id = payments.sale_id
  where sales.branch_id = session_row.branch_id
    and sales.created_at >= session_row.opened_at
    and payments.payment_method = 'cash';
  select coalesce(sum(returns.refund_amount), 0) into session_row.cash_refunds
  from public.sale_returns returns
  join public.sales sales on sales.id = returns.sale_id
  where sales.branch_id = session_row.branch_id
    and returns.created_at >= session_row.opened_at
    and returns.refund_method = 'cash';
  update public.register_sessions
  set closed_by = auth.uid(), closing_cash = target_closing_cash,
      cash_sales = session_row.cash_sales, cash_refunds = session_row.cash_refunds,
      status = 'closed', closed_at = now(),
      notes = case when trim(coalesce(target_notes, '')) = '' then notes else target_notes end
  where id = target_session_id returning * into session_row;
  return to_jsonb(session_row);
end;
$$;

create or replace function public.create_purchase_order(
  target_store_id uuid,
  target_branch_id uuid,
  target_supplier_id uuid,
  target_expected_at timestamptz,
  target_notes text,
  purchase_lines_input jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare order_row public.purchase_orders%rowtype;
  product_row public.products%rowtype;
  item jsonb;
  total_value numeric := 0;
begin
  if not public.has_store_role(target_store_id, array['owner', 'manager']) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if not exists (select 1 from public.branches where id = target_branch_id and store_id = target_store_id)
     or not exists (select 1 from public.suppliers where id = target_supplier_id and store_id = target_store_id and is_active)
     or jsonb_array_length(coalesce(purchase_lines_input, '[]'::jsonb)) = 0 then
    raise exception 'INVALID_PURCHASE_ORDER';
  end if;
  for item in select * from jsonb_array_elements(purchase_lines_input)
  loop
    if (item->>'quantity')::numeric <= 0 or (item->>'unit_cost')::numeric < 0 then
      raise exception 'INVALID_PURCHASE_LINE';
    end if;
    total_value := total_value +
      (item->>'quantity')::numeric * (item->>'unit_cost')::numeric;
  end loop;
  insert into public.purchase_orders(
    store_id, branch_id, supplier_id, order_number, status, expected_at,
    notes, total_cost, created_by
  ) values (
    target_store_id, target_branch_id, target_supplier_id, 'PENDING', 'ordered',
    target_expected_at, coalesce(target_notes, ''), total_value, auth.uid()
  ) returning * into order_row;
  update public.purchase_orders
  set order_number = 'PO-' || to_char(now(), 'YYMM') || '-' ||
    lpad(order_row.sequence_number::text, 6, '0')
  where id = order_row.id;
  for item in select * from jsonb_array_elements(purchase_lines_input)
  loop
    select * into product_row from public.products
    where id = (item->>'product_id')::uuid and store_id = target_store_id and is_active;
    if not found then raise exception 'PRODUCT_NOT_FOUND'; end if;
    insert into public.purchase_order_lines(
      purchase_order_id, store_id, product_id, product_name, quantity, unit_cost
    ) values (
      order_row.id, target_store_id, product_row.id, product_row.name,
      (item->>'quantity')::numeric, (item->>'unit_cost')::numeric
    );
  end loop;
  return order_row.id;
end;
$$;

create or replace function public.receive_purchase_order(target_purchase_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare order_row public.purchase_orders%rowtype;
  line_row public.purchase_order_lines%rowtype;
  level_row public.inventory_levels%rowtype;
  received numeric;
  new_cost numeric;
begin
  select * into order_row from public.purchase_orders
  where id = target_purchase_order_id and status in ('ordered', 'partially_received')
  for update;
  if not found or not public.has_store_role(order_row.store_id, array['owner', 'manager']) then
    raise exception 'PURCHASE_ORDER_NOT_RECEIVABLE';
  end if;
  for line_row in select * from public.purchase_order_lines
    where purchase_order_id = target_purchase_order_id for update
  loop
    received := line_row.quantity - line_row.received_quantity;
    if received > 0 then
      insert into public.inventory_levels(
        store_id, branch_id, product_id, on_hand, reorder_point, average_cost
      ) select order_row.store_id, order_row.branch_id, line_row.product_id,
          0, products.reorder_point, 0 from public.products
          where id = line_row.product_id
      on conflict (branch_id, product_id) do nothing;
      select * into level_row from public.inventory_levels
      where branch_id = order_row.branch_id and product_id = line_row.product_id
      for update;
      new_cost := case when level_row.on_hand + received = 0 then line_row.unit_cost
        else ((level_row.on_hand * level_row.average_cost) +
          (received * line_row.unit_cost)) / (level_row.on_hand + received) end;
      update public.inventory_levels
      set on_hand = on_hand + received, average_cost = round(new_cost, 3),
          updated_at = now()
      where id = level_row.id;
      update public.purchase_order_lines
      set received_quantity = quantity where id = line_row.id;
      insert into public.stock_movements(
        store_id, branch_id, product_id, movement_type, quantity, unit_cost,
        reference_type, reference_id, note, created_by
      ) values (
        order_row.store_id, order_row.branch_id, line_row.product_id, 'purchase',
        received, line_row.unit_cost, 'purchase_order', order_row.id,
        order_row.order_number, auth.uid()
      );
    end if;
  end loop;
  update public.purchase_orders set status = 'received', updated_at = now()
  where id = order_row.id;
end;
$$;

create or replace function public.delete_current_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare owned_store public.stores%rowtype;
  successor uuid;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  for owned_store in select * from public.stores where owner_id = auth.uid()
  loop
    select user_id into successor from public.store_members
    where store_id = owned_store.id and user_id <> auth.uid() and status = 'active'
    order by case role when 'manager' then 0 else 1 end, joined_at
    limit 1;
    if successor is null then
      delete from public.stores where id = owned_store.id;
    else
      update public.store_members set role = 'owner' where store_id = owned_store.id and user_id = successor;
      update public.stores set owner_id = successor where id = owned_store.id;
    end if;
    successor := null;
  end loop;
  delete from auth.users where id = auth.uid();
end;
$$;

create trigger inventory_levels_updated_at before update on public.inventory_levels
for each row execute function public.set_updated_at();
create trigger sales_updated_at before update on public.sales
for each row execute function public.set_updated_at();
create trigger suppliers_updated_at before update on public.suppliers
for each row execute function public.set_updated_at();
create trigger purchase_orders_updated_at before update on public.purchase_orders
for each row execute function public.set_updated_at();

alter table public.inventory_levels enable row level security;
alter table public.stock_movements enable row level security;
alter table public.sales enable row level security;
alter table public.sale_lines enable row level security;
alter table public.sale_payments enable row level security;
alter table public.sale_returns enable row level security;
alter table public.sale_return_lines enable row level security;
alter table public.register_sessions enable row level security;
alter table public.suppliers enable row level security;
alter table public.purchase_orders enable row level security;
alter table public.purchase_order_lines enable row level security;

create policy inventory_select_members on public.inventory_levels for select to authenticated
using (public.is_store_member(store_id));
create policy movements_select_members on public.stock_movements for select to authenticated
using (public.is_store_member(store_id));
create policy sales_select_members on public.sales for select to authenticated
using (public.is_store_member(store_id));
create policy sale_lines_select_members on public.sale_lines for select to authenticated
using (public.is_store_member(store_id));
create policy sale_payments_select_members on public.sale_payments for select to authenticated
using (public.is_store_member(store_id));
create policy sale_returns_select_members on public.sale_returns for select to authenticated
using (public.is_store_member(store_id));
create policy sale_return_lines_select_members on public.sale_return_lines for select to authenticated
using (exists (
  select 1 from public.sale_returns returns
  where returns.id = return_id and public.is_store_member(returns.store_id)
));
create policy registers_select_members on public.register_sessions for select to authenticated
using (public.is_store_member(store_id));
create policy suppliers_select_members on public.suppliers for select to authenticated
using (public.is_store_member(store_id));
create policy suppliers_insert_managers on public.suppliers for insert to authenticated
with check (public.has_store_role(store_id, array['owner', 'manager']));
create policy suppliers_update_managers on public.suppliers for update to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']))
with check (public.has_store_role(store_id, array['owner', 'manager']));
create policy suppliers_delete_managers on public.suppliers for delete to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']));
create policy purchase_orders_select_members on public.purchase_orders for select to authenticated
using (public.is_store_member(store_id));
create policy purchase_lines_select_members on public.purchase_order_lines for select to authenticated
using (public.is_store_member(store_id));

revoke all on table public.inventory_levels from anon, authenticated;
revoke all on table public.stock_movements from anon, authenticated;
revoke all on table public.sales from anon, authenticated;
revoke all on table public.sale_lines from anon, authenticated;
revoke all on table public.sale_payments from anon, authenticated;
revoke all on table public.sale_returns from anon, authenticated;
revoke all on table public.sale_return_lines from anon, authenticated;
revoke all on table public.register_sessions from anon, authenticated;
revoke all on table public.suppliers from anon, authenticated;
revoke all on table public.purchase_orders from anon, authenticated;
revoke all on table public.purchase_order_lines from anon, authenticated;

grant select on table public.inventory_levels to authenticated;
grant select on table public.stock_movements to authenticated;
grant select on table public.sales to authenticated;
grant select on table public.sale_lines to authenticated;
grant select on table public.sale_payments to authenticated;
grant select on table public.sale_returns to authenticated;
grant select on table public.sale_return_lines to authenticated;
grant select on table public.register_sessions to authenticated;
grant select, insert, update, delete on table public.suppliers to authenticated;
grant select on table public.purchase_orders to authenticated;
grant select on table public.purchase_order_lines to authenticated;

revoke all on function public.adjust_inventory(uuid, uuid, uuid, numeric, numeric, text) from public;
revoke all on function public.transfer_inventory(uuid, uuid, uuid, uuid, numeric, text) from public;
revoke all on function public.create_sale(uuid, uuid, uuid, text, text, jsonb, jsonb, numeric, text) from public;
revoke all on function public.return_sale(uuid, uuid, jsonb, text, text) from public;
revoke all on function public.open_register(uuid, uuid, numeric, text) from public;
revoke all on function public.close_register(uuid, numeric, text) from public;
revoke all on function public.create_purchase_order(uuid, uuid, uuid, timestamptz, text, jsonb) from public;
revoke all on function public.receive_purchase_order(uuid) from public;
revoke all on function public.delete_current_account() from public;

grant execute on function public.adjust_inventory(uuid, uuid, uuid, numeric, numeric, text) to authenticated;
grant execute on function public.transfer_inventory(uuid, uuid, uuid, uuid, numeric, text) to authenticated;
grant execute on function public.create_sale(uuid, uuid, uuid, text, text, jsonb, jsonb, numeric, text) to authenticated;
grant execute on function public.return_sale(uuid, uuid, jsonb, text, text) to authenticated;
grant execute on function public.open_register(uuid, uuid, numeric, text) to authenticated;
grant execute on function public.close_register(uuid, numeric, text) to authenticated;
grant execute on function public.create_purchase_order(uuid, uuid, uuid, timestamptz, text, jsonb) to authenticated;
grant execute on function public.receive_purchase_order(uuid) to authenticated;
grant execute on function public.delete_current_account() to authenticated;
