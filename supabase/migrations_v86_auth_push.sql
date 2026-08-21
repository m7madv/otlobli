-- RETIRED: do not deploy this historical, non-timestamped migration.
--
-- The production identity schema is now defined by the ordered migrations in
-- supabase/migrations/, including:
--   20260821090000_production_auth_push.sql
--   20260821183000_apple_authorization_client_id.sql
--   20260821193000_harden_identity_rpc_permissions.sql
--
-- Keeping an executable copy here could regress Apple provider support and
-- reopen SECURITY DEFINER functions to anonymous callers. Fail loudly if an
-- old runbook attempts to apply this path.
do $$
begin
  raise exception 'migrations_v86_auth_push.sql is retired; deploy timestamped migrations instead';
end;
$$;
