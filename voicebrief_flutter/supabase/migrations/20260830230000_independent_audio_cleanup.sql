begin;

alter table public.audio_upload_reservations
  add column consumed_at timestamptz,
  add column cleanup_first_removed_at timestamptz,
  add column cleanup_claim_id uuid,
  add column cleanup_claimed_at timestamptz,
  add column cleanup_attempts bigint not null default 0
    check (cleanup_attempts >= 0),
  add constraint audio_upload_reservations_hard_expiry_check
    check (expires_at <= created_at + interval '4 hours');

create index audio_upload_reservations_cleanup_idx
  on public.audio_upload_reservations(expires_at, cleanup_claimed_at)
  where cleanup_first_removed_at is null;
create index audio_upload_reservations_cleanup_verify_idx
  on public.audio_upload_reservations(cleanup_first_removed_at, cleanup_claimed_at)
  where cleanup_first_removed_at is not null;

create or replace function public.reserve_voicebrief_upload(
  p_user_id uuid,
  p_job_id uuid,
  p_storage_path text,
  p_size_bytes integer,
  p_mime_type text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing public.audio_upload_reservations%rowtype;
  v_issued integer;
begin
  if p_user_id is null or p_job_id is null then
    raise exception 'invalid_upload_identity';
  end if;
  if p_storage_path !~ ('^' || p_user_id::text || '/' || p_job_id::text || '/input\.(flac|mp3|mp4|mpeg|mpga|m4a|ogg|wav|webm)$') then
    raise exception 'invalid_storage_path';
  end if;
  if p_size_bytes <= 0 or p_size_bytes > 26214400 then
    raise exception 'invalid_file_size';
  end if;
  if p_mime_type not in ('audio/flac','audio/mpeg','audio/mp4','audio/wav','audio/ogg','audio/webm') then
    raise exception 'unsupported_audio';
  end if;

  perform 1 from public.profiles where user_id = p_user_id for update;
  if not found then raise exception 'profile_missing'; end if;

  select * into v_existing
  from public.audio_upload_reservations
  where user_id = p_user_id and job_id = p_job_id
  for update;
  if found and v_existing.expires_at > now()
      and v_existing.created_at > now() - interval '2 hours'
      and v_existing.storage_path = p_storage_path
      and v_existing.expected_size_bytes = p_size_bytes
      and v_existing.expected_mime_type = p_mime_type then
    -- A retry may need a fresh two-hour signed URL, but the retry window closes
    -- two hours after creation and the reservation has an immutable four-hour
    -- lifetime ceiling. This keeps every issued URL discoverable without a
    -- sliding reservation that can evade cleanup forever.
    update public.audio_upload_reservations
    set expires_at = least(
          now() + interval '2 hours',
          v_existing.created_at + interval '4 hours'
        ),
        consumed_at = null
    where user_id = p_user_id and job_id = p_job_id;
    return jsonb_build_object('state', 'existing');
  elsif found and (
      v_existing.expires_at <= now()
      or v_existing.created_at <= now() - interval '2 hours'
    ) then
    -- Do not renew a path while the asynchronous cleaner may own or soon claim it.
    -- A later retry can reserve the same job after verification removes the row.
    return jsonb_build_object('state', 'cleanup_pending');
  elsif found then
    raise exception 'upload_reservation_conflict';
  end if;

  if (
    select count(*)
    from public.audio_upload_reservations
    where user_id = p_user_id
      and expires_at > now()
      and consumed_at is null
  ) >= 3 then
    return jsonb_build_object('state', 'rate_limited');
  end if;

  insert into public.audio_upload_daily_limits(user_id, day_utc, issued_count)
  values (p_user_id, timezone('UTC', now())::date, 1)
  on conflict (user_id, day_utc) do update
    set issued_count = public.audio_upload_daily_limits.issued_count + 1
    where public.audio_upload_daily_limits.issued_count < 20
  returning issued_count into v_issued;
  if v_issued is null then
    return jsonb_build_object('state', 'rate_limited');
  end if;

  insert into public.audio_upload_reservations(
    user_id, job_id, storage_path, expected_size_bytes, expected_mime_type
  ) values (
    p_user_id, p_job_id, p_storage_path, p_size_bytes, p_mime_type
  );
  return jsonb_build_object('state', 'reserved');
end;
$$;

create or replace function public.release_voicebrief_upload(
  p_user_id uuid,
  p_job_id uuid
)
returns void
language sql
security definer
set search_path = public
as $$
  -- Keep a tombstone through signed-URL expiry. A delayed upload then remains
  -- discoverable by the independent Storage cleaner.
  update public.audio_upload_reservations
  set consumed_at = now()
  where user_id = p_user_id
    and job_id = p_job_id
    and cleanup_claim_id is null;
$$;

create or replace function public.claim_expired_voicebrief_uploads(
  p_limit integer default 100
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_claim_id uuid := gen_random_uuid();
  v_storage_paths text[];
begin
  if p_limit is null or p_limit < 1 or p_limit > 100 then
    raise exception 'invalid_cleanup_limit';
  end if;

  with candidates as (
    select user_id, job_id
    from public.audio_upload_reservations
    where (
        (
          cleanup_first_removed_at is null
          and expires_at <= now() - interval '15 minutes'
        )
        or cleanup_first_removed_at <= now() - interval '15 minutes'
      )
      and (
        cleanup_claimed_at is null
        or cleanup_claimed_at <= now() - interval '30 minutes'
      )
    order by coalesce(cleanup_first_removed_at, expires_at)
    limit p_limit
    for update skip locked
  ), claimed as (
    update public.audio_upload_reservations as reservation
    set cleanup_claim_id = v_claim_id,
        cleanup_claimed_at = now(),
        cleanup_attempts = reservation.cleanup_attempts + 1
    from candidates
    where reservation.user_id = candidates.user_id
      and reservation.job_id = candidates.job_id
    returning reservation.storage_path
  )
  select coalesce(
    array_agg(storage_path order by storage_path),
    array[]::text[]
  ) into v_storage_paths
  from claimed;

  if cardinality(v_storage_paths) = 0 then
    return jsonb_build_object(
      'claimId', null,
      'storagePaths', jsonb_build_array()
    );
  end if;
  return jsonb_build_object(
    'claimId', v_claim_id,
    'storagePaths', to_jsonb(v_storage_paths)
  );
end;
$$;

create or replace function public.complete_expired_voicebrief_upload_cleanup(
  p_claim_id uuid,
  p_storage_paths text[]
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_staged integer := 0;
  v_deleted integer := 0;
begin
  if p_claim_id is null or p_storage_paths is null
      or cardinality(p_storage_paths) < 1
      or cardinality(p_storage_paths) > 100 then
    raise exception 'invalid_cleanup_completion';
  end if;

  -- A verification claim has already survived the conservative interval after
  -- the first Storage removal. Its second removal can now retire the pointer.
  delete from public.audio_upload_reservations
  where cleanup_claim_id = p_claim_id
    and storage_path = any(p_storage_paths)
    and cleanup_first_removed_at is not null;
  get diagnostics v_deleted = row_count;

  -- The first successful Storage removal only stages a tombstone. Clearing the
  -- lease lets a later run claim it for the independent verification removal.
  update public.audio_upload_reservations
  set cleanup_first_removed_at = now(),
      cleanup_claim_id = null,
      cleanup_claimed_at = null
  where cleanup_claim_id = p_claim_id
    and storage_path = any(p_storage_paths)
    and cleanup_first_removed_at is null;
  get diagnostics v_staged = row_count;

  return jsonb_build_object('staged', v_staged, 'deleted', v_deleted);
end;
$$;

create or replace function public.release_expired_voicebrief_upload_cleanup(
  p_claim_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_released integer := 0;
begin
  if p_claim_id is null then
    raise exception 'invalid_cleanup_release';
  end if;
  update public.audio_upload_reservations
  set cleanup_claim_id = null,
      cleanup_claimed_at = null
  where cleanup_claim_id = p_claim_id;
  get diagnostics v_released = row_count;
  return v_released;
end;
$$;

revoke all on function public.claim_expired_voicebrief_uploads(integer)
  from public, anon, authenticated;
revoke all on function public.complete_expired_voicebrief_upload_cleanup(uuid, text[])
  from public, anon, authenticated;
revoke all on function public.release_expired_voicebrief_upload_cleanup(uuid)
  from public, anon, authenticated;
grant execute on function public.claim_expired_voicebrief_uploads(integer)
  to service_role;
grant execute on function public.complete_expired_voicebrief_upload_cleanup(uuid, text[])
  to service_role;
grant execute on function public.release_expired_voicebrief_upload_cleanup(uuid)
  to service_role;
revoke all on function public.reserve_voicebrief_upload(uuid, uuid, text, integer, text)
  from public, anon, authenticated;
grant execute on function public.reserve_voicebrief_upload(uuid, uuid, text, integer, text)
  to service_role;
revoke all on function public.release_voicebrief_upload(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.release_voicebrief_upload(uuid, uuid)
  to service_role;

create extension if not exists supabase_vault with schema vault;
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron;

create or replace function public.invoke_voicebrief_expired_audio_cleanup()
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_project_url text;
  v_secret_key text;
  v_request_id bigint;
begin
  select decrypted_secret into v_project_url
  from vault.decrypted_secrets
  where name = 'voicebrief_project_url';
  select decrypted_secret into v_secret_key
  from vault.decrypted_secrets
  where name = 'voicebrief_secret_key';

  if nullif(trim(v_project_url), '') is null
      or nullif(v_secret_key, '') is null then
    raise exception 'voicebrief_cleanup_vault_not_configured';
  end if;

  select net.http_post(
    url := rtrim(v_project_url, '/') || '/functions/v1/cleanup-expired-audio',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', v_secret_key
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  ) into v_request_id;
  return v_request_id;
end;
$$;

revoke all on function public.invoke_voicebrief_expired_audio_cleanup()
  from public, anon, authenticated, service_role;

do $$
begin
  if not exists (
    select 1 from cron.job
    where jobname = 'voicebrief-expired-audio-cleanup'
  ) then
    perform cron.schedule(
      'voicebrief-expired-audio-cleanup',
      '*/15 * * * *',
      'select public.invoke_voicebrief_expired_audio_cleanup()'
    );
  end if;
end;
$$;

commit;
