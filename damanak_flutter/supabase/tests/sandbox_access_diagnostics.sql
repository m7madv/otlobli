-- Read-only operational diagnostics. Run as the project owner; no account,
-- receipt, token, email, or other personal identifiers are returned.
begin read only;

select platform,
  count(*) as tester_rows,
  count(*) filter (where expires_at > now()) as active_testers,
  count(*) filter (where expires_at <= now()) as expired_testers,
  max(expires_at) as latest_expiry
from private.store_sandbox_testers
group by platform;

select platform,
  count(*) filter (
    where revoked_at is null and opens_at <= now() and closes_at > now()
      and grants_used < max_grants
  ) as open_windows_with_seats,
  count(*) filter (where revoked_at is not null) as revoked_windows,
  count(*) filter (where closes_at <= now()) as elapsed_windows
from private.store_sandbox_review_windows
group by platform;

select platform,
  count(*) as grants,
  count(*) filter (where expires_at > now()) as unexpired_grants,
  count(*) filter (where expires_at <= now()) as expired_grants
from private.store_sandbox_review_grants
group by platform;

select platform, environment, status,
  count(*) as entitlements,
  count(*) filter (where superseded_at is null) as current_rows
from public.store_entitlements
group by platform, environment, status;

rollback;
