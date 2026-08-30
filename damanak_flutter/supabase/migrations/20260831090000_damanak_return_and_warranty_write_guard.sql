-- Extend the business-write paywall to the two remaining direct store tables.
-- return_sale sets a transaction-local, server-controlled context after it
-- validates membership and locks the sale, so contractual refunds still work.

do $remaining_write_triggers$
declare
  table_name text;
begin
  foreach table_name in array array['sale_returns', 'warranties'] loop
    execute format(
      'drop trigger if exists %I on public.%I',
      table_name || '_usable_subscription_guard',
      table_name
    );
    execute format(
      'drop trigger if exists %I on public.%I',
      table_name || '_00_subscription_write_guard',
      table_name
    );
    execute format(
      'create trigger %I before insert or update on public.%I '
      || 'for each row execute function '
      || 'public.enforce_usable_subscription_for_core_write()',
      table_name || '_00_subscription_write_guard',
      table_name
    );
  end loop;
end;
$remaining_write_triggers$;

do $verification$
begin
  if exists (
    select 1
    from pg_catalog.pg_proc procedure
    join pg_catalog.pg_namespace namespace
      on namespace.oid = procedure.pronamespace
    where namespace.nspname = 'public'
      and pg_catalog.has_function_privilege(
        'anon', procedure.oid, 'EXECUTE'
      )
  ) then
    raise exception 'DAMANAK_ANON_FUNCTION_EXECUTE_REMAINS';
  end if;
end;
$verification$;
