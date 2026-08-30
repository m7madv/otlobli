-- A polymorphic trigger record only exposes fields from the table currently
-- firing it. Access register-specific fields through JSON so product, stock,
-- supplier, and other writes do not fail while evaluating the close exception.

create or replace function public.enforce_usable_subscription_for_core_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_store_id uuid;
begin
  if coalesce((select auth.role()), '') <> 'authenticated' then
    return new;
  end if;

  if current_setting('damanak.write_context', true) = 'return_sale' then
    return new;
  end if;

  if tg_table_name = 'register_sessions' and tg_op = 'UPDATE'
     and to_jsonb(old)->>'status' = 'open'
     and to_jsonb(new)->>'status' = 'closed'
     and to_jsonb(new)->>'id' = to_jsonb(old)->>'id'
     and to_jsonb(new)->>'store_id' = to_jsonb(old)->>'store_id'
     and to_jsonb(new)->>'branch_id' = to_jsonb(old)->>'branch_id'
     and to_jsonb(new)->>'opened_by' = to_jsonb(old)->>'opened_by'
     and to_jsonb(new)->>'opened_at' = to_jsonb(old)->>'opened_at' then
    return new;
  end if;

  target_store_id := nullif(to_jsonb(new)->>'store_id', '')::uuid;
  if target_store_id is null then
    raise exception 'STORE_REQUIRED';
  end if;
  if not public.subscription_is_usable(target_store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;
  return new;
end;
$$;

revoke all on function public.enforce_usable_subscription_for_core_write()
  from public, anon, authenticated;
