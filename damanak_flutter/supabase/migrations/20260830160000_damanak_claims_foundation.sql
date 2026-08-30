-- Rich warranty-claim workflow. This migration keeps the existing
-- maintenance_requests table so installed clients continue to work.

create sequence if not exists public.maintenance_claim_number_seq;

alter table public.maintenance_requests
  drop constraint if exists maintenance_requests_status_check;

alter table public.maintenance_requests
  alter column created_by drop not null,
  add column if not exists claim_number bigint,
  add column if not exists category text not null default 'other',
  add column if not exists priority text not null default 'normal',
  add column if not exists channel text not null default 'staff',
  add column if not exists resolution text not null default 'none',
  add column if not exists customer_notes text not null default '',
  add column if not exists internal_notes text not null default '',
  add column if not exists diagnosis text not null default '',
  add column if not exists resolution_notes text not null default '',
  add column if not exists decision_reason text not null default '',
  add column if not exists service_branch_id uuid references public.branches(id) on delete set null,
  add column if not exists sla_due_at timestamptz,
  add column if not exists approved_at timestamptz,
  add column if not exists completed_at timestamptz,
  add column if not exists updated_by uuid references auth.users(id) on delete set null,
  add column if not exists version integer not null default 1;

update public.maintenance_requests
set claim_number = nextval('public.maintenance_claim_number_seq')
where claim_number is null;

alter table public.maintenance_requests
  alter column claim_number set default nextval('public.maintenance_claim_number_seq'),
  alter column claim_number set not null,
  add constraint maintenance_requests_status_check
    check (status in (
      'new',
      'needs_review',
      'approved',
      'in_progress',
      'waiting_for_customer',
      'ready_for_pickup',
      'completed',
      'rejected',
      'cancelled'
    )),
  add constraint maintenance_requests_category_check
    check (category in (
      'malfunction', 'battery', 'software', 'physical_damage',
      'missing_parts', 'other'
    )),
  add constraint maintenance_requests_priority_check
    check (priority in ('low', 'normal', 'high', 'urgent')),
  add constraint maintenance_requests_channel_check
    check (channel in ('staff', 'customer_portal', 'import', 'api')),
  add constraint maintenance_requests_resolution_check
    check (resolution in (
      'none', 'repair', 'replacement', 'refund', 'external_service', 'rejected'
    )),
  add constraint maintenance_requests_version_check check (version > 0);

create unique index if not exists maintenance_store_claim_number_idx
  on public.maintenance_requests(store_id, claim_number);
create index if not exists maintenance_store_status_updated_idx
  on public.maintenance_requests(store_id, status, updated_at desc);
create index if not exists maintenance_assignee_open_idx
  on public.maintenance_requests(store_id, assigned_to, sla_due_at)
  where status not in ('completed', 'rejected', 'cancelled');

create table if not exists public.maintenance_request_events (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.maintenance_requests(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  event_type text not null check (event_type in (
    'created', 'status_changed', 'assigned', 'details_updated',
    'customer_message', 'staff_message', 'attachment_added'
  )),
  old_status text,
  new_status text,
  title text not null check (char_length(trim(title)) between 2 and 160),
  details jsonb not null default '{}'::jsonb,
  is_customer_visible boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists maintenance_events_request_created_idx
  on public.maintenance_request_events(request_id, created_at desc);
create index if not exists maintenance_events_store_created_idx
  on public.maintenance_request_events(store_id, created_at desc);

create or replace function public.guard_maintenance_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  warranty_store_id uuid;
  branch_store_id uuid;
  actor_role text;
  allowed_transition boolean;
begin
  select store_id into warranty_store_id
  from public.warranties
  where id = new.warranty_id;

  if warranty_store_id is null or warranty_store_id <> new.store_id then
    raise exception 'CLAIM_WARRANTY_STORE_MISMATCH';
  end if;

  if new.service_branch_id is not null then
    select store_id into branch_store_id
    from public.branches
    where id = new.service_branch_id;
    if branch_store_id is null or branch_store_id <> new.store_id then
      raise exception 'CLAIM_BRANCH_STORE_MISMATCH';
    end if;
  end if;

  if new.assigned_to is not null and not exists (
    select 1
    from public.store_members member
    where member.store_id = new.store_id
      and member.user_id = new.assigned_to
      and member.status = 'active'
  ) then
    raise exception 'CLAIM_ASSIGNEE_INVALID';
  end if;

  new.customer_notes = trim(coalesce(new.customer_notes, ''));
  new.internal_notes = trim(coalesce(new.internal_notes, ''));
  new.diagnosis = trim(coalesce(new.diagnosis, ''));
  new.resolution_notes = trim(coalesce(new.resolution_notes, ''));
  new.decision_reason = trim(coalesce(new.decision_reason, ''));

  if tg_op = 'INSERT' then
    new.version = 1;
    new.updated_by = coalesce(new.updated_by, new.created_by);
    new.sla_due_at = coalesce(
      new.sla_due_at,
      now() + case new.priority
        when 'urgent' then interval '4 hours'
        when 'high' then interval '24 hours'
        when 'low' then interval '72 hours'
        else interval '48 hours'
      end
    );
    return new;
  end if;

  allowed_transition := new.status = old.status or case old.status
    when 'new' then new.status in ('needs_review', 'approved', 'in_progress', 'waiting_for_customer', 'rejected', 'cancelled')
    when 'needs_review' then new.status in ('approved', 'in_progress', 'waiting_for_customer', 'rejected', 'cancelled')
    when 'approved' then new.status in ('in_progress', 'waiting_for_customer', 'rejected', 'cancelled')
    when 'in_progress' then new.status in ('waiting_for_customer', 'ready_for_pickup', 'completed', 'rejected', 'cancelled')
    when 'waiting_for_customer' then new.status in ('needs_review', 'approved', 'in_progress', 'cancelled')
    when 'ready_for_pickup' then new.status in ('in_progress', 'completed', 'cancelled')
    when 'completed' then new.status in ('in_progress')
    when 'rejected' then new.status in ('needs_review')
    when 'cancelled' then new.status in ('needs_review')
    else false
  end;

  if not allowed_transition then
    raise exception 'CLAIM_STATUS_TRANSITION_INVALID';
  end if;

  if (select auth.uid()) is not null then
    select member.role into actor_role
    from public.store_members member
    where member.store_id = new.store_id
      and member.user_id = (select auth.uid())
      and member.status = 'active';

    if actor_role is null then
      raise exception 'CLAIM_STORE_ACCESS_DENIED';
    end if;

    if (
      (new.status in ('approved', 'rejected') and new.status <> old.status)
      or (new.resolution in ('refund', 'rejected') and new.resolution <> old.resolution)
      or (old.status in ('completed', 'rejected', 'cancelled') and new.status <> old.status)
    ) and actor_role not in ('owner', 'manager') then
      raise exception 'CLAIM_MANAGER_REQUIRED';
    end if;
  end if;

  if new.status = 'rejected' and new.decision_reason = '' then
    raise exception 'CLAIM_DECISION_REASON_REQUIRED';
  end if;

  if new.status = 'approved' and old.status <> 'approved' then
    new.approved_at = now();
  end if;
  if new.status = 'completed' and old.status <> 'completed' then
    new.completed_at = now();
  elsif new.status <> 'completed' then
    new.completed_at = null;
  end if;

  new.version = old.version + 1;
  new.updated_by = coalesce(new.updated_by, (select auth.uid()));
  return new;
end;
$$;

drop trigger if exists maintenance_requests_guard on public.maintenance_requests;
create trigger maintenance_requests_guard
before insert or update on public.maintenance_requests
for each row execute function public.guard_maintenance_request();

create or replace function public.record_maintenance_request_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  event_name text;
  event_title text;
  customer_visible boolean := false;
begin
  if tg_op = 'INSERT' then
    event_name := 'created';
    event_title := 'تم تسجيل المطالبة';
    customer_visible := true;
  elsif new.status is distinct from old.status then
    event_name := 'status_changed';
    event_title := 'تم تحديث حالة المطالبة';
    customer_visible := true;
  elsif new.assigned_to is distinct from old.assigned_to then
    event_name := 'assigned';
    event_title := 'تم تعيين مسؤول المطالبة';
  else
    event_name := 'details_updated';
    event_title := 'تم تحديث تفاصيل المطالبة';
  end if;

  insert into public.maintenance_request_events (
    request_id,
    store_id,
    event_type,
    old_status,
    new_status,
    title,
    is_customer_visible,
    created_by
  ) values (
    new.id,
    new.store_id,
    event_name,
    case when tg_op = 'UPDATE' then old.status else null end,
    new.status,
    event_title,
    customer_visible,
    coalesce(new.updated_by, new.created_by)
  );
  return new;
end;
$$;

drop trigger if exists maintenance_requests_record_event on public.maintenance_requests;
create trigger maintenance_requests_record_event
after insert or update on public.maintenance_requests
for each row execute function public.record_maintenance_request_event();

create or replace function public.update_maintenance_request(
  target_request_id uuid,
  expected_version integer,
  patch jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_request public.maintenance_requests;
  updated_request public.maintenance_requests;
  unknown_keys text[];
begin
  select * into current_request
  from public.maintenance_requests
  where id = target_request_id
  for update;

  if current_request.id is null then
    raise exception 'CLAIM_NOT_FOUND';
  end if;
  if not public.is_store_member(current_request.store_id) then
    raise exception 'CLAIM_STORE_ACCESS_DENIED';
  end if;
  if current_request.version <> expected_version then
    raise exception 'CLAIM_VERSION_CONFLICT';
  end if;

  select array_agg(keys.key) into unknown_keys
  from jsonb_object_keys(coalesce(patch, '{}'::jsonb)) as keys(key)
  where key not in (
    'status', 'category', 'priority', 'resolution', 'customer_notes',
    'internal_notes', 'diagnosis', 'resolution_notes', 'decision_reason',
    'assigned_to', 'service_branch_id', 'sla_due_at'
  );
  if unknown_keys is not null then
    raise exception 'CLAIM_PATCH_INVALID';
  end if;

  update public.maintenance_requests
  set
    status = coalesce(patch->>'status', status),
    category = coalesce(patch->>'category', category),
    priority = coalesce(patch->>'priority', priority),
    resolution = coalesce(patch->>'resolution', resolution),
    customer_notes = case when patch ? 'customer_notes' then coalesce(patch->>'customer_notes', '') else customer_notes end,
    internal_notes = case when patch ? 'internal_notes' then coalesce(patch->>'internal_notes', '') else internal_notes end,
    diagnosis = case when patch ? 'diagnosis' then coalesce(patch->>'diagnosis', '') else diagnosis end,
    resolution_notes = case when patch ? 'resolution_notes' then coalesce(patch->>'resolution_notes', '') else resolution_notes end,
    decision_reason = case when patch ? 'decision_reason' then coalesce(patch->>'decision_reason', '') else decision_reason end,
    assigned_to = case when patch ? 'assigned_to' then nullif(patch->>'assigned_to', '')::uuid else assigned_to end,
    service_branch_id = case when patch ? 'service_branch_id' then nullif(patch->>'service_branch_id', '')::uuid else service_branch_id end,
    sla_due_at = case when patch ? 'sla_due_at' then nullif(patch->>'sla_due_at', '')::timestamptz else sla_due_at end,
    updated_by = (select auth.uid()),
    updated_at = now()
  where id = target_request_id
  returning * into updated_request;

  return to_jsonb(updated_request);
end;
$$;

alter table public.maintenance_request_events enable row level security;

create policy maintenance_events_select_members
on public.maintenance_request_events for select to authenticated
using (public.is_store_member(store_id));

revoke all on table public.maintenance_request_events from anon, authenticated;
grant select on table public.maintenance_request_events to authenticated;

revoke all on sequence public.maintenance_claim_number_seq from anon, authenticated;
grant usage, select on sequence public.maintenance_claim_number_seq to authenticated;

revoke all on function public.update_maintenance_request(uuid, integer, jsonb) from public;
grant execute on function public.update_maintenance_request(uuid, integer, jsonb) to authenticated;

revoke all on function public.guard_maintenance_request() from public;
revoke all on function public.record_maintenance_request_event() from public;
