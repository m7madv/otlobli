-- Close entitlement-expiry and concurrency gaps across plan features.

create or replace function public.store_plan_allows(
  target_store_id uuid,
  entitlement_name text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select case entitlement_name
      when 'api' then plan.api_access
      when 'webhook' then plan.webhook_access
      when 'branding' then plan.custom_branding
      else false
    end
    from public.subscriptions subscription
    join public.plans plan on plan.id = subscription.plan_id
    where subscription.store_id = target_store_id
      and (
        (subscription.status = 'trialing' and subscription.trial_ends_at > now())
        or
        (subscription.status = 'active' and (
          subscription.current_period_end is null
          or subscription.current_period_end > now()
        ))
      )
    limit 1
  ), false)
$$;

create or replace function public.enforce_branch_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  branch_limit integer;
  current_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':branches', 0)
  );
  select plan.max_branches into branch_limit
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = new.store_id
    and (
      (subscription.status = 'trialing' and subscription.trial_ends_at > now())
      or
      (subscription.status = 'active' and (
        subscription.current_period_end is null
        or subscription.current_period_end > now()
      ))
    );
  if branch_limit is null then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;
  select count(*) into current_count
  from public.branches
  where store_id = new.store_id and is_active;
  if current_count >= branch_limit then
    raise exception 'BRANCH_LIMIT_REACHED';
  end if;
  return new;
end;
$$;

create or replace function public.join_store_by_code(invitation_code text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  invite public.invite_codes%rowtype;
  allowed_members integer;
  active_members integer;
  existing_status text;
begin
  if (select auth.uid()) is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select * into invite
  from public.invite_codes
  where code_hash = digest(upper(trim(invitation_code)), 'sha256')
    and is_active
    and expires_at > now()
    and used_count < max_uses
  for update;

  if invite.id is null then
    raise exception 'INVITE_INVALID';
  end if;
  if not public.subscription_is_usable(invite.store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  -- Different invite rows for the same store must share one seat lock.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(invite.store_id::text || ':members', 0)
  );

  select plans.max_members into allowed_members
  from public.subscriptions
  join public.plans on plans.id = subscriptions.plan_id
  where subscriptions.store_id = invite.store_id;
  if allowed_members is null then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  select count(*) into active_members
  from public.store_members
  where store_id = invite.store_id and status = 'active';
  select status into existing_status
  from public.store_members
  where store_id = invite.store_id and user_id = (select auth.uid());

  if active_members >= allowed_members
     and coalesce(existing_status, '') <> 'active' then
    raise exception 'SEAT_LIMIT_REACHED';
  end if;

  insert into public.store_members(store_id, user_id, role, status)
  values (invite.store_id, (select auth.uid()), invite.role, 'active')
  on conflict (store_id, user_id) do update set
    role = excluded.role,
    status = 'active',
    updated_at = now();

  update public.invite_codes
  set used_count = used_count + 1,
      is_active = used_count + 1 < max_uses
  where id = invite.id;

  insert into public.audit_logs(store_id, user_id, action, entity_type, entity_id)
  values (
    invite.store_id, (select auth.uid()), 'member_joined',
    'member', (select auth.uid())
  );

  return jsonb_build_object(
    'store_id', invite.store_id,
    'user_id', (select auth.uid()),
    'role', invite.role,
    'status', 'active'
  );
end;
$$;

create or replace function public.claim_ai_import_job(
  target_store_id uuid,
  target_user_id uuid,
  target_filename text,
  target_mime_type text,
  target_size_bytes bigint,
  target_provider text,
  target_pricing_tier text,
  target_model text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  monthly_limit integer;
  monthly_used integer;
  daily_used integer;
  created_id uuid;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if not exists (
    select 1 from public.store_members
    where store_id = target_store_id
      and user_id = target_user_id
      and role in ('owner', 'manager')
      and status = 'active'
  ) then
    raise exception 'IMPORT_MANAGER_REQUIRED';
  end if;
  if target_provider not in ('gemini', 'openai')
     or target_pricing_tier not in ('free', 'paid') then
    raise exception 'AI_PROVIDER_INVALID';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_store_id::text || ':ai-import', 0)
  );
  select plan.monthly_ai_imports into monthly_limit
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = target_store_id
    and (
      (subscription.status = 'trialing' and subscription.trial_ends_at > now())
      or
      (subscription.status = 'active' and (
        subscription.current_period_end is null
        or subscription.current_period_end > now()
      ))
    );
  if coalesce(monthly_limit, 0) < 1 then
    raise exception 'AI_IMPORT_NOT_INCLUDED';
  end if;

  select count(*) into monthly_used
  from public.ai_import_jobs
  where store_id = target_store_id
    and created_at >= pg_catalog.date_trunc('month', now());
  select count(*) into daily_used
  from public.ai_import_jobs
  where store_id = target_store_id
    and created_at >= now() - interval '24 hours';
  if monthly_used >= monthly_limit then
    raise exception 'AI_IMPORT_MONTHLY_LIMIT';
  end if;
  if daily_used >= 25 then
    raise exception 'AI_IMPORT_DAILY_SAFETY_LIMIT';
  end if;

  insert into public.ai_import_jobs(
    store_id, user_id, status, filename, mime_type, size_bytes,
    provider, pricing_tier, model
  ) values (
    target_store_id, target_user_id, 'started', target_filename,
    target_mime_type, target_size_bytes, target_provider,
    target_pricing_tier, target_model
  ) returning id into created_id;

  return jsonb_build_object(
    'jobId', created_id,
    'monthlyLimit', monthly_limit,
    'monthlyUsed', monthly_used + 1
  );
end;
$$;

create or replace function public.claim_ai_claim_review_job(
  target_store_id uuid,
  target_request_id uuid,
  target_user_id uuid,
  target_model text,
  target_include_attachments boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  monthly_limit integer;
  monthly_used integer;
  recent_used integer;
  created_id uuid;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if not exists (
    select 1 from public.store_members
    where store_id = target_store_id
      and user_id = target_user_id
      and role in ('owner', 'manager')
      and status = 'active'
  ) or not exists (
    select 1 from public.maintenance_requests
    where id = target_request_id and store_id = target_store_id
  ) then
    raise exception 'CLAIM_REVIEW_ACCESS_DENIED';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_store_id::text || ':claim-ai', 0)
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_request_id::text || ':claim-ai', 0)
  );
  select plan.monthly_ai_claim_reviews into monthly_limit
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = target_store_id
    and (
      (subscription.status = 'trialing' and subscription.trial_ends_at > now())
      or
      (subscription.status = 'active' and (
        subscription.current_period_end is null
        or subscription.current_period_end > now()
      ))
    );
  if coalesce(monthly_limit, 0) < 1 then
    raise exception 'CLAIM_AI_NOT_INCLUDED';
  end if;

  select count(*) into monthly_used
  from public.ai_claim_reviews
  where store_id = target_store_id
    and created_at >= pg_catalog.date_trunc('month', now());
  select count(*) into recent_used
  from public.ai_claim_reviews
  where request_id = target_request_id
    and created_at >= now() - interval '10 minutes';
  if monthly_used >= monthly_limit then
    raise exception 'CLAIM_AI_MONTHLY_LIMIT';
  end if;
  if recent_used >= 1 then
    raise exception 'CLAIM_AI_COOLDOWN';
  end if;

  insert into public.ai_claim_reviews(
    store_id, request_id, user_id, status, provider, model,
    included_attachments
  ) values (
    target_store_id, target_request_id, target_user_id, 'started',
    'openai', target_model, target_include_attachments
  ) returning id into created_id;

  return jsonb_build_object(
    'jobId', created_id,
    'monthlyLimit', monthly_limit,
    'monthlyUsed', monthly_used + 1
  );
end;
$$;

create or replace function public.reserve_api_request(
  target_key_id uuid,
  target_store_id uuid,
  target_method text,
  target_path text
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  recent_count integer;
  request_log_id bigint;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if not exists (
    select 1 from public.store_api_keys
    where id = target_key_id and store_id = target_store_id
      and revoked_at is null
  ) then
    raise exception 'API_KEY_INVALID';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_key_id::text || ':api-hour', 0)
  );
  select count(*) into recent_count
  from public.api_request_logs
  where key_id = target_key_id
    and created_at >= now() - interval '1 hour';
  if recent_count >= 300 then
    return null;
  end if;
  insert into public.api_request_logs(
    key_id, store_id, method, path, response_status
  ) values (
    target_key_id, target_store_id, left(target_method, 16),
    left(target_path, 200), 0
  ) returning id into request_log_id;
  return request_log_id;
end;
$$;

create or replace function public.finish_api_request(
  target_log_id bigint,
  target_status integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if target_status not between 100 and 599 then
    raise exception 'API_STATUS_INVALID';
  end if;
  update public.api_request_logs
  set response_status = target_status
  where id = target_log_id;
end;
$$;

revoke all on function public.claim_ai_import_job(
  uuid, uuid, text, text, bigint, text, text, text
) from public, anon, authenticated;
revoke all on function public.claim_ai_claim_review_job(
  uuid, uuid, uuid, text, boolean
) from public, anon, authenticated;
revoke all on function public.reserve_api_request(
  uuid, uuid, text, text
) from public, anon, authenticated;
revoke all on function public.finish_api_request(bigint, integer)
  from public, anon, authenticated;

grant execute on function public.claim_ai_import_job(
  uuid, uuid, text, text, bigint, text, text, text
) to service_role;
grant execute on function public.claim_ai_claim_review_job(
  uuid, uuid, uuid, text, boolean
) to service_role;
grant execute on function public.reserve_api_request(
  uuid, uuid, text, text
) to service_role;
grant execute on function public.finish_api_request(bigint, integer)
  to service_role;

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
