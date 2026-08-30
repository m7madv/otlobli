-- Free in-app notifications. Push delivery is intentionally not claimed until
-- APNs/FCM credentials and device tokens are configured.

create table if not exists public.notification_preferences (
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  claim_created boolean not null default true,
  claim_assigned boolean not null default true,
  claim_overdue boolean not null default true,
  ready_for_pickup boolean not null default true,
  marketing boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (store_id, user_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null check (event_type in (
    'claim_created', 'claim_assigned', 'claim_overdue',
    'ready_for_pickup', 'system'
  )),
  title text not null check (char_length(trim(title)) between 2 and 120),
  body text not null default '' check (char_length(body) <= 500),
  request_id uuid references public.maintenance_requests(id) on delete cascade,
  dedupe_key text not null check (char_length(dedupe_key) between 8 and 200),
  read_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, dedupe_key)
);

create index if not exists notifications_user_unread_idx
  on public.notifications(user_id, created_at desc) where read_at is null;
create index if not exists notifications_store_created_idx
  on public.notifications(store_id, created_at desc);

create or replace function public.create_claim_notifications()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  member_row record;
  claim_reference text;
begin
  claim_reference := 'CLM-' || lpad(coalesce(new.claim_number, 0)::text, 6, '0');

  if tg_op = 'INSERT' then
    for member_row in
      select member.user_id
      from public.store_members member
      left join public.notification_preferences preference
        on preference.store_id = member.store_id
       and preference.user_id = member.user_id
      where member.store_id = new.store_id
        and member.status = 'active'
        and member.role in ('owner', 'manager')
        and coalesce(preference.claim_created, true)
    loop
      insert into public.notifications(
        store_id, user_id, event_type, title, body, request_id, dedupe_key
      ) values (
        new.store_id, member_row.user_id, 'claim_created',
        'مطالبة جديدة ' || claim_reference,
        left(new.issue, 500), new.id, 'claim-created:' || new.id::text
      ) on conflict (user_id, dedupe_key) do nothing;
    end loop;
    return new;
  end if;

  if new.assigned_to is distinct from old.assigned_to and new.assigned_to is not null then
    if exists (
      select 1 from public.store_members member
      left join public.notification_preferences preference
        on preference.store_id = member.store_id
       and preference.user_id = member.user_id
      where member.store_id = new.store_id
        and member.user_id = new.assigned_to
        and member.status = 'active'
        and coalesce(preference.claim_assigned, true)
    ) then
      insert into public.notifications(
        store_id, user_id, event_type, title, body, request_id, dedupe_key
      ) values (
        new.store_id, new.assigned_to, 'claim_assigned',
        'أُسندت إليك ' || claim_reference,
        left(new.issue, 500), new.id,
        'claim-assigned:' || new.id::text || ':' || new.assigned_to::text || ':' || new.version::text
      ) on conflict (user_id, dedupe_key) do nothing;
    end if;
  end if;

  if new.status = 'ready_for_pickup' and old.status is distinct from new.status then
    for member_row in
      select member.user_id
      from public.store_members member
      left join public.notification_preferences preference
        on preference.store_id = member.store_id
       and preference.user_id = member.user_id
      where member.store_id = new.store_id
        and member.status = 'active'
        and (member.role in ('owner', 'manager') or member.user_id = new.assigned_to)
        and coalesce(preference.ready_for_pickup, true)
    loop
      insert into public.notifications(
        store_id, user_id, event_type, title, body, request_id, dedupe_key
      ) values (
        new.store_id, member_row.user_id, 'ready_for_pickup',
        'جاهزة للاستلام ' || claim_reference,
        'تواصل مع العميل لتنسيق الاستلام.', new.id,
        'claim-ready:' || new.id::text || ':' || new.version::text
      ) on conflict (user_id, dedupe_key) do nothing;
    end loop;
  end if;
  return new;
end;
$$;

drop trigger if exists maintenance_requests_notifications
  on public.maintenance_requests;
create trigger maintenance_requests_notifications
after insert or update of assigned_to, status on public.maintenance_requests
for each row execute function public.create_claim_notifications();

create or replace function public.enqueue_overdue_claim_notifications(
  target_store_id uuid
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  inserted_count integer := 0;
begin
  if not exists (
    select 1 from public.store_members member
    where member.store_id = target_store_id
      and member.user_id = auth.uid()
      and member.status = 'active'
  ) then
    raise exception 'STORE_MEMBER_REQUIRED';
  end if;

  insert into public.notifications(
    store_id, user_id, event_type, title, body, request_id, dedupe_key
  )
  select
    request.store_id,
    member.user_id,
    'claim_overdue',
    'مطالبة متأخرة CLM-' || lpad(request.claim_number::text, 6, '0'),
    'تجاوزت موعد المتابعة المحدد. افتحها وحدّث الخطوة التالية.',
    request.id,
    'claim-overdue:' || request.id::text || ':' || current_date::text
  from public.maintenance_requests request
  join public.store_members member
    on member.store_id = request.store_id
   and member.status = 'active'
   and (member.role in ('owner', 'manager') or member.user_id = request.assigned_to)
  left join public.notification_preferences preference
    on preference.store_id = member.store_id
   and preference.user_id = member.user_id
  where request.store_id = target_store_id
    and request.sla_due_at < now()
    and request.status not in ('completed', 'rejected', 'cancelled')
    and coalesce(preference.claim_overdue, true)
  on conflict (user_id, dedupe_key) do nothing;

  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;

alter table public.notification_preferences enable row level security;
alter table public.notifications enable row level security;

create policy notification_preferences_own
on public.notification_preferences for all to authenticated
using (user_id = auth.uid() and public.has_store_role(store_id, array['owner', 'manager', 'staff']))
with check (user_id = auth.uid() and public.has_store_role(store_id, array['owner', 'manager', 'staff']));

create policy notifications_select_own
on public.notifications for select to authenticated
using (user_id = auth.uid() and public.has_store_role(store_id, array['owner', 'manager', 'staff']));

create policy notifications_update_own
on public.notifications for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

revoke all on table public.notification_preferences from anon, authenticated;
revoke all on table public.notifications from anon, authenticated;
grant select, insert, update on table public.notification_preferences to authenticated;
grant select, update on table public.notifications to authenticated;

revoke all on function public.create_claim_notifications() from public;
revoke all on function public.enqueue_overdue_claim_notifications(uuid) from public;
grant execute on function public.enqueue_overdue_claim_notifications(uuid)
  to authenticated;
