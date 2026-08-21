-- Bind each stored Apple refresh token to the exact client_id that issued it.
-- Existing records predate Android Services ID support and were all issued to
-- the native iOS bundle identifier.

alter table public.apple_authorizations
  add column if not exists client_id text;
alter table public.apple_authorizations
  add column if not exists pending_expires_at timestamptz;

update public.apple_authorizations
set client_id = 'com.otlobli.app'
where client_id is null or trim(client_id) = '';

update public.apple_authorizations
set pending_expires_at = now() + interval '15 minutes'
where customer_id is null and pending_expires_at is null;

alter table public.apple_authorizations
  alter column client_id set not null;

-- A user can authorize the native iOS bundle and the associated web Services
-- ID independently. Keep both refresh grants so account deletion can revoke
-- every authorization instead of overwriting the previous platform's token.
alter table public.apple_authorizations
  drop constraint if exists apple_authorizations_pkey;
alter table public.apple_authorizations
  add constraint apple_authorizations_pkey
  primary key (provider_user_id, client_id);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.apple_authorizations'::regclass
      and conname = 'apple_authorizations_client_id_nonempty'
  ) then
    alter table public.apple_authorizations
      add constraint apple_authorizations_client_id_nonempty
      check (char_length(trim(client_id)) between 3 and 255);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.apple_authorizations'::regclass
      and conname = 'apple_authorizations_pending_expiry'
  ) then
    alter table public.apple_authorizations
      add constraint apple_authorizations_pending_expiry
      check (customer_id is not null or pending_expires_at is not null);
  end if;
end $$;

create index if not exists apple_authorizations_pending_expiry_idx
  on public.apple_authorizations (pending_expires_at)
  where customer_id is null;
