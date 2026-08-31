-- Live integration contract for migration 20260831140000.
-- Run with: supabase db query --linked --file supabase/tests/warranty_tenant_integrity_live.sql
-- Every write is enclosed in a transaction that is always rolled back.

begin;
set local statement_timeout = '15s';
set local lock_timeout = '5s';

-- Product and warranty write guards are irrelevant to this referential-integrity
-- test. USER triggers are disabled transactionally; internal FK triggers remain.
alter table public.customers disable trigger user;
alter table public.products disable trigger user;
alter table public.sales disable trigger user;
alter table public.sale_lines disable trigger user;
alter table public.warranties disable trigger user;
alter table public.maintenance_requests disable trigger user;

do $test$
declare
  store_a uuid;
  store_b uuid;
  owner_a uuid;
  owner_b uuid;
  branch_a uuid;
  branch_b uuid;
  customer_a uuid := gen_random_uuid();
  customer_b uuid := gen_random_uuid();
  product_a uuid := gen_random_uuid();
  product_b uuid := gen_random_uuid();
  sale_a uuid := gen_random_uuid();
  sale_b uuid := gen_random_uuid();
  sale_line_a uuid := gen_random_uuid();
  sale_line_b uuid := gen_random_uuid();
  warranty_a uuid := gen_random_uuid();
  hit_constraint text;
begin
  select store_id, owner_id, branch_id
  into store_a, owner_a, branch_a
  from (
    select s.id as store_id, s.owner_id, b.id as branch_id,
      row_number() over (order by s.created_at, s.id) as row_number
    from public.stores s
    join lateral (
      select id from public.branches
      where store_id = s.id
      order by is_main desc, created_at, id
      limit 1
    ) b on true
    where s.owner_id is not null
  ) candidates
  where row_number = 1;

  select store_id, owner_id, branch_id
  into store_b, owner_b, branch_b
  from (
    select s.id as store_id, s.owner_id, b.id as branch_id,
      row_number() over (order by s.created_at, s.id) as row_number
    from public.stores s
    join lateral (
      select id from public.branches
      where store_id = s.id
      order by is_main desc, created_at, id
      limit 1
    ) b on true
    where s.owner_id is not null
  ) candidates
  where row_number = 2;

  if store_a is null or store_b is null then
    raise exception 'The live tenant test requires two stores with branches and owners';
  end if;

  insert into public.customers(id, store_id, name, phone, created_by)
  values
    (customer_a, store_a, 'عميل اختبار أ', '70000001', owner_a),
    (customer_b, store_b, 'عميل اختبار ب', '70000002', owner_b);

  insert into public.products(id, store_id, name, created_by)
  values
    (product_a, store_a, 'منتج اختبار أ', owner_a),
    (product_b, store_b, 'منتج اختبار ب', owner_b);

  insert into public.sales(
    id, store_id, branch_id, invoice_number, subtotal, total, currency_code
  ) values
    (sale_a, store_a, branch_a, 'SEC-A-' || left(sale_a::text, 8), 1, 1, 'QAR'),
    (sale_b, store_b, branch_b, 'SEC-B-' || left(sale_b::text, 8), 1, 1, 'QAR');

  insert into public.sale_lines(
    id, sale_id, store_id, product_id, product_name, quantity,
    unit_price, line_total
  ) values
    (sale_line_a, sale_a, store_a, product_a, 'منتج اختبار أ', 1, 1, 1),
    (sale_line_b, sale_b, store_b, product_b, 'منتج اختبار ب', 1, 1, 1);

  -- A fully same-store warranty must remain valid.
  insert into public.warranties(
    id, warranty_number, store_id, product_id, customer_name, customer_phone,
    product_name, purchase_date, expiry_date, created_by, customer_id,
    branch_id, sale_id, sale_line_id
  ) values (
    warranty_a, 'SEC-VALID-' || left(gen_random_uuid()::text, 8), store_a, product_a,
    'عميل اختبار أ', '70000001', 'منتج اختبار أ', current_date,
    current_date + 1, owner_a, customer_a, branch_a, sale_a, sale_line_a
  );

  insert into public.maintenance_requests(
    store_id, warranty_id, issue, created_by
  ) values (
    store_a, warranty_a, 'مطالبة اختبار صحيحة', owner_a
  );

  begin
    insert into public.maintenance_requests(
      store_id, warranty_id, issue, created_by
    ) values (
      store_b, warranty_a, 'مطالبة اختبار عابرة', owner_b
    );
    raise exception 'Cross-store maintenance request was accepted';
  exception when foreign_key_violation then
    get stacked diagnostics hit_constraint = constraint_name;
    if hit_constraint <> 'maintenance_requests_warranty_store_fk' then raise; end if;
  end;

  begin
    insert into public.warranties(
      warranty_number, store_id, customer_name, customer_phone, product_name,
      purchase_date, expiry_date, created_by, customer_id
    ) values (
      'SEC-CUSTOMER-' || left(gen_random_uuid()::text, 8), store_a,
      'عميل اختبار', '70000003', 'منتج اختبار', current_date,
      current_date + 1, owner_a, customer_b
    );
    raise exception 'Cross-store customer_id was accepted';
  exception when foreign_key_violation then
    get stacked diagnostics hit_constraint = constraint_name;
    if hit_constraint <> 'warranties_customer_store_fk' then raise; end if;
  end;

  begin
    insert into public.warranties(
      warranty_number, store_id, product_id, customer_name, customer_phone,
      product_name, purchase_date, expiry_date, created_by, customer_id
    ) values (
      'SEC-PRODUCT-' || left(gen_random_uuid()::text, 8), store_a, product_b,
      'عميل اختبار', '70000003', 'منتج اختبار', current_date,
      current_date + 1, owner_a, customer_a
    );
    raise exception 'Cross-store product_id was accepted';
  exception when foreign_key_violation then
    get stacked diagnostics hit_constraint = constraint_name;
    if hit_constraint <> 'warranties_product_store_fk' then raise; end if;
  end;

  begin
    insert into public.warranties(
      warranty_number, store_id, customer_name, customer_phone, product_name,
      purchase_date, expiry_date, created_by, customer_id, branch_id
    ) values (
      'SEC-BRANCH-' || left(gen_random_uuid()::text, 8), store_a,
      'عميل اختبار', '70000003', 'منتج اختبار', current_date,
      current_date + 1, owner_a, customer_a, branch_b
    );
    raise exception 'Cross-store branch_id was accepted';
  exception when foreign_key_violation then
    get stacked diagnostics hit_constraint = constraint_name;
    if hit_constraint <> 'warranties_branch_store_fk' then raise; end if;
  end;

  begin
    insert into public.warranties(
      warranty_number, store_id, customer_name, customer_phone, product_name,
      purchase_date, expiry_date, created_by, customer_id, sale_id
    ) values (
      'SEC-SALE-' || left(gen_random_uuid()::text, 8), store_a,
      'عميل اختبار', '70000003', 'منتج اختبار', current_date,
      current_date + 1, owner_a, customer_a, sale_b
    );
    raise exception 'Cross-store sale_id was accepted';
  exception when foreign_key_violation then
    get stacked diagnostics hit_constraint = constraint_name;
    if hit_constraint <> 'warranties_sale_store_fk' then raise; end if;
  end;

  begin
    insert into public.warranties(
      warranty_number, store_id, customer_name, customer_phone, product_name,
      purchase_date, expiry_date, created_by, customer_id, sale_line_id
    ) values (
      'SEC-LINE-' || left(gen_random_uuid()::text, 8), store_a,
      'عميل اختبار', '70000003', 'منتج اختبار', current_date,
      current_date + 1, owner_a, customer_a, sale_line_b
    );
    raise exception 'Cross-store sale_line_id was accepted';
  exception when foreign_key_violation then
    get stacked diagnostics hit_constraint = constraint_name;
    if hit_constraint <> 'warranties_sale_line_store_fk' then raise; end if;
  end;

  -- Parent drift must also be rejected after a valid relationship exists.
  begin
    update public.customers set store_id = store_b where id = customer_a;
    raise exception 'A referenced customer was moved across stores';
  exception when foreign_key_violation then
    get stacked diagnostics hit_constraint = constraint_name;
    if hit_constraint <> 'warranties_customer_store_fk' then raise; end if;
  end;
end
$test$;

rollback;

select 'warranty tenant integrity passed; transaction rolled back' as result;
