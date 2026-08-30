-- A later migration replaced this trigger function after the blanket function
-- privilege hardening. PostgreSQL grants EXECUTE to PUBLIC on newly-created
-- functions unless it is revoked explicitly, so close that narrow regression.

revoke all on function public.audit_business_change()
  from public, anon, authenticated;

-- Keep this invariant executable as part of every deployment: anonymous users
-- must not be able to invoke any routine in the public application schema.
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
end;
$verification$;

comment on function public.audit_business_change() is
  'Trigger-only audit routine; direct execution is denied to API roles.';
