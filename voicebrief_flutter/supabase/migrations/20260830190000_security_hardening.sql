begin;

create table public.audio_upload_reservations (
  user_id uuid not null references auth.users(id) on delete cascade,
  job_id uuid not null,
  storage_path text not null unique,
  expected_size_bytes integer not null check (expected_size_bytes > 0 and expected_size_bytes <= 26214400),
  expected_mime_type text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '2 hours'),
  primary key (user_id, job_id),
  check (storage_path ~ ('^' || user_id::text || '/' || job_id::text || '/input\.(flac|mp3|mp4|mpeg|mpga|m4a|ogg|wav|webm)$')),
  check (expected_mime_type in ('audio/flac','audio/mpeg','audio/mp4','audio/wav','audio/ogg','audio/webm'))
);

create table public.audio_upload_daily_limits (
  user_id uuid not null references auth.users(id) on delete cascade,
  day_utc date not null,
  issued_count integer not null default 0 check (issued_count between 0 and 20),
  primary key (user_id, day_utc)
);

alter table public.audio_upload_reservations enable row level security;
alter table public.audio_upload_daily_limits enable row level security;

create index audio_upload_reservations_expiry_idx
  on public.audio_upload_reservations(expires_at);

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
      and v_existing.storage_path = p_storage_path
      and v_existing.expected_size_bytes = p_size_bytes
      and v_existing.expected_mime_type = p_mime_type then
    return jsonb_build_object('state', 'existing');
  elsif found then
    raise exception 'upload_reservation_conflict';
  end if;

  if (
    select count(*)
    from public.audio_upload_reservations
    where user_id = p_user_id and expires_at > now()
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
  delete from public.audio_upload_reservations
  where user_id = p_user_id and job_id = p_job_id;
$$;

create or replace function public.purge_expired_voicebrief_jobs()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job record;
  v_failed integer := 0;
  v_redacted integer := 0;
begin
  for v_job in
    select user_id, id
    from public.processing_jobs
    where expires_at <= now() and status in ('reserving', 'processing')
    for update skip locked
  loop
    perform public.fail_voicebrief_job(v_job.user_id, v_job.id, 'job_expired');
    v_failed := v_failed + 1;
  end loop;

  update public.processing_jobs
  set result = null, error_code = 'result_expired', updated_at = now()
  where expires_at <= now() and status = 'completed' and result is not null;
  get diagnostics v_redacted = row_count;

  delete from public.audio_upload_daily_limits
  where day_utc < timezone('UTC', now())::date - 7;

  return jsonb_build_object(
    'failedJobs', v_failed,
    'redactedResults', v_redacted
  );
end;
$$;

drop policy if exists "jobs_read_own" on public.processing_jobs;
drop policy if exists "processing_jobs_read_own" on public.processing_jobs;
create policy "processing_jobs_read_own" on public.processing_jobs for select
  using (auth.uid() = user_id and expires_at > now());

drop policy if exists "audio_insert_own_folder" on storage.objects;

revoke all on table public.audio_upload_reservations from public, anon, authenticated;
revoke all on table public.audio_upload_daily_limits from public, anon, authenticated;
grant all on table public.audio_upload_reservations to service_role;
grant all on table public.audio_upload_daily_limits to service_role;

revoke all on function public.reserve_voicebrief_upload(uuid, uuid, text, integer, text)
  from public, anon, authenticated;
revoke all on function public.release_voicebrief_upload(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.purge_expired_voicebrief_jobs()
  from public, anon, authenticated;
grant execute on function public.reserve_voicebrief_upload(uuid, uuid, text, integer, text)
  to service_role;
grant execute on function public.release_voicebrief_upload(uuid, uuid)
  to service_role;
grant execute on function public.purge_expired_voicebrief_jobs()
  to service_role;

create or replace function public.submit_voicebrief_support_request(
  p_request_key_hash text,
  p_email text,
  p_category text,
  p_subject text,
  p_message text,
  p_language text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recent_count integer;
begin
  if p_request_key_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid_request_key';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_request_key_hash, 0));
  select count(*) into v_recent_count
  from public.support_requests
  where request_key_hash = p_request_key_hash
    and created_at >= now() - interval '24 hours';
  if v_recent_count >= 5 then return 'rate_limited'; end if;

  insert into public.support_requests(
    email, category, subject, message, language, request_key_hash
  ) values (
    p_email, p_category, p_subject, p_message, p_language, p_request_key_hash
  );
  return 'accepted';
end;
$$;

revoke all on function public.submit_voicebrief_support_request(text, text, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.submit_voicebrief_support_request(text, text, text, text, text, text)
  to service_role;

create extension if not exists pg_cron;
do $$
begin
  if not exists (select 1 from cron.job where jobname = 'voicebrief-expired-job-cleanup') then
    perform cron.schedule(
      'voicebrief-expired-job-cleanup',
      '*/15 * * * *',
      'select public.purge_expired_voicebrief_jobs()'
    );
  end if;
end;
$$;

commit;
