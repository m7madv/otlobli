-- Harden the public RPC surface, serialize warranty quota checks, acquire sale
-- inventory locks deterministically, and add the highest-value missing indexes.
-- This migration intentionally preserves existing warranty numbers and sale RPC
-- argument names so deployed clients remain compatible.

-- Read-path and foreign-key indexes used by the current application/RPCs.
create index if not exists customers_store_updated_idx
  on public.customers(store_id, updated_at desc);

create index if not exists inventory_levels_store_updated_idx
  on public.inventory_levels(store_id, updated_at desc);

create index if not exists warranties_store_active_created_idx
  on public.warranties(store_id, created_at desc)
  where voided_at is null;

create index if not exists warranties_sale_line_active_idx
  on public.warranties(sale_line_id)
  where sale_line_id is not null and voided_at is null;

create index if not exists sale_returns_sale_idx
  on public.sale_returns(sale_id);

create index if not exists sale_return_lines_return_idx
  on public.sale_return_lines(return_id);

create index if not exists sale_return_lines_sale_line_idx
  on public.sale_return_lines(sale_line_id);

-- A global sequence removes the birthday-collision risk of the previous
-- eight-hex-character suffix. The S marker and twelve-hex-character sequence
-- keep new numbers distinct from every legacy auto-generated format. Sequence
-- gaps on transaction rollback are expected and do not affect correctness.
create sequence if not exists public.warranty_number_seq
  as bigint
  increment by 1
  minvalue 1
  no maxvalue
  start with 1
  cache 1;

revoke all privileges on sequence public.warranty_number_seq
  from public, anon, authenticated;

-- Preserve the published plan quotas and the existing 10% operational buffer.
-- The advisory transaction lock serializes the count-and-insert decision for a
-- store while allowing different stores to issue warranties concurrently.
create or replace function public.enforce_warranty_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  included_limit integer;
  effective_limit integer;
  used_count bigint;
begin
  if not public.subscription_is_usable(new.store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text, 0)
  );

  select plan.monthly_warranties
  into included_limit
  from public.subscriptions as subscription
  join public.plans as plan on plan.id = subscription.plan_id
  where subscription.store_id = new.store_id;

  if included_limit is null then
    raise exception 'SUBSCRIPTION_PLAN_NOT_FOUND';
  end if;

  effective_limit := included_limit
    + pg_catalog.ceil(included_limit::numeric * 0.10)::integer;

  select pg_catalog.count(*)
  into used_count
  from public.warranties as warranty
  where warranty.store_id = new.store_id
    and warranty.voided_at is null
    and warranty.created_at >= pg_catalog.date_trunc('month', pg_catalog.now())
    and warranty.created_at <
      pg_catalog.date_trunc('month', pg_catalog.now()) + interval '1 month';

  if used_count >= effective_limit then
    raise exception 'WARRANTY_LIMIT_REACHED';
  end if;

  if new.warranty_number is null or new.warranty_number = '' then
    new.warranty_number :=
      'DMN-' || pg_catalog.to_char(pg_catalog.now(), 'YYMM') || '-S' ||
      pg_catalog.upper(
        pg_catalog.lpad(
          pg_catalog.to_hex(
            pg_catalog.nextval('public.warranty_number_seq'::pg_catalog.regclass)
          ),
          12,
          '0'
        )
      );
  end if;

  return new;
end;
$function$;

-- Lock every tracked inventory row required by a sale in one canonical order.
-- DISTINCT also prevents duplicate product lines from acquiring the same lock
-- repeatedly during the pre-lock phase. Existing create_sale validation remains
-- authoritative and repeats FOR UPDATE safely after these locks are held.
create or replace function private.lock_sale_inventory(
  target_store_id uuid,
  target_branch_id uuid,
  sale_lines_input jsonb
)
returns void
language plpgsql
security invoker
set search_path = ''
as $function$
begin
  perform inventory.id
  from public.inventory_levels as inventory
  join (
    select distinct (input.line ->> 'product_id')::uuid as product_id
    from pg_catalog.jsonb_array_elements(
      coalesce(sale_lines_input, '[]'::jsonb)
    ) as input(line)
  ) as requested on requested.product_id = inventory.product_id
  join public.products as product
    on product.id = requested.product_id
   and product.store_id = target_store_id
   and product.is_active
  where inventory.store_id = target_store_id
    and inventory.branch_id = target_branch_id
    and product.track_inventory
  order by inventory.product_id
  for update of inventory;
end;
$function$;

revoke all
on function private.lock_sale_inventory(uuid, uuid, jsonb)
from public, anon, authenticated;

-- Keep the already-tested sale implementation byte-for-byte by moving it behind
-- a private name. The public wrapper performs authorization/basic scope checks,
-- acquires all inventory locks deterministically, verifies the aggregate
-- quantity of duplicate product lines, then calls the original body in the same
-- transaction.
alter function public.create_sale(
  uuid, uuid, uuid, text, text, jsonb, jsonb, numeric, text
) set schema private;

alter function private.create_sale(
  uuid, uuid, uuid, text, text, jsonb, jsonb, numeric, text
) rename to create_sale_unlocked;

revoke all
on function private.create_sale_unlocked(
  uuid, uuid, uuid, text, text, jsonb, jsonb, numeric, text
)
from public, anon, authenticated;

create function public.create_sale(
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
set search_path = ''
as $function$
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;

  if pg_catalog.jsonb_array_length(
       coalesce(sale_lines_input, '[]'::jsonb)
     ) = 0 then
    raise exception 'EMPTY_SALE';
  end if;

  if not exists (
    select 1
    from public.branches as branch
    where branch.id = target_branch_id
      and branch.store_id = target_store_id
      and branch.is_active
      and branch.accepts_sales
  ) then
    raise exception 'BRANCH_SALES_DISABLED';
  end if;

  perform private.lock_sale_inventory(
    target_store_id,
    target_branch_id,
    sale_lines_input
  );

  -- The original implementation validates each line independently. Once the
  -- canonical locks are held, aggregate duplicate product lines so two valid
  -- individual lines cannot jointly exceed the available stock.
  if exists (
    with requested_inventory as (
      select
        (input.line ->> 'product_id')::uuid as product_id,
        pg_catalog.sum((input.line ->> 'quantity')::numeric)
          as requested_quantity
      from pg_catalog.jsonb_array_elements(sale_lines_input) as input(line)
      group by (input.line ->> 'product_id')::uuid
    )
    select 1
    from requested_inventory as requested
    join public.products as product
      on product.id = requested.product_id
     and product.store_id = target_store_id
     and product.is_active
     and product.track_inventory
    left join public.inventory_levels as inventory
      on inventory.store_id = target_store_id
     and inventory.branch_id = target_branch_id
     and inventory.product_id = requested.product_id
    where inventory.id is null
       or inventory.on_hand - inventory.reserved
          < requested.requested_quantity
  ) then
    raise exception 'INSUFFICIENT_STOCK';
  end if;

  return private.create_sale_unlocked(
    target_store_id,
    target_branch_id,
    target_customer_id,
    target_customer_name,
    target_customer_phone,
    sale_lines_input,
    sale_payments_input,
    order_discount,
    target_notes
  );
end;
$function$;

comment on function private.create_sale_unlocked(
  uuid, uuid, uuid, text, text, jsonb, jsonb, numeric, text
) is 'Internal Damanak sale implementation; call public.create_sale so inventory rows are pre-locked deterministically.';

-- Remove default callable-function exposure. authenticated is also reset here
-- and receives only the policy helpers and RPCs used by the shipped client.
revoke execute on all functions in schema public
  from public, anon, authenticated;

alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated;

alter default privileges for role postgres in schema private
  revoke execute on functions from public, anon, authenticated;

grant execute on function public.is_store_member(uuid)
  to authenticated;
grant execute on function public.has_store_role(uuid, text[])
  to authenticated;
grant execute on function public.shares_store(uuid)
  to authenticated;
grant execute on function public.subscription_is_usable(uuid)
  to authenticated;
grant execute on function public.current_warranty_usage(uuid)
  to authenticated;
grant execute on function public.create_store_with_trial(text, text, text, text)
  to authenticated;
grant execute on function public.create_store_invite(uuid, text, integer)
  to authenticated;
grant execute on function public.join_store_by_code(text)
  to authenticated;
grant execute on function public.update_store_member(uuid, uuid, text, text)
  to authenticated;

grant execute on function public.adjust_inventory(
  uuid, uuid, uuid, numeric, numeric, text
) to authenticated;
grant execute on function public.transfer_inventory(
  uuid, uuid, uuid, uuid, numeric, text
) to authenticated;
grant execute on function public.create_sale(
  uuid, uuid, uuid, text, text, jsonb, jsonb, numeric, text
) to authenticated;
grant execute on function public.return_sale(uuid, uuid, jsonb, text, text)
  to authenticated;
grant execute on function public.open_register(uuid, uuid, numeric, text)
  to authenticated;
grant execute on function public.close_register(uuid, numeric, text)
  to authenticated;
grant execute on function public.create_purchase_order(
  uuid, uuid, uuid, timestamptz, text, jsonb
) to authenticated;
grant execute on function public.receive_purchase_order(uuid)
  to authenticated;
grant execute on function public.delete_current_account()
  to authenticated;

-- Keep the member-directory view query-only and unavailable to anonymous users.
revoke all privileges on table public.store_member_directory
  from public, anon, authenticated;
grant select on table public.store_member_directory
  to authenticated;

-- Fail the migration if any public-schema function is still executable by anon
-- (has_function_privilege also accounts for privileges inherited from PUBLIC).
do $verification$
begin
  if exists (
    select 1
    from pg_catalog.pg_proc as procedure
    join pg_catalog.pg_namespace as namespace
      on namespace.oid = procedure.pronamespace
    where namespace.nspname = 'public'
      and pg_catalog.has_function_privilege(
        'anon', procedure.oid, 'EXECUTE'
      )
  ) then
    raise exception 'DAMANAK_ANON_FUNCTION_EXECUTE_REMAINS';
  end if;

  if pg_catalog.has_table_privilege(
    'anon', 'public.store_member_directory', 'SELECT'
  ) then
    raise exception 'DAMANAK_ANON_MEMBER_DIRECTORY_ACCESS_REMAINS';
  end if;
end;
$verification$;
