-- Customer self-service claim submission and private attachment metadata.

alter table public.maintenance_requests
  add column if not exists public_submission_id uuid;

create unique index if not exists maintenance_public_submission_idx
  on public.maintenance_requests(public_submission_id)
  where public_submission_id is not null;

create table if not exists public.maintenance_request_attachments (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.maintenance_requests(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  storage_path text not null unique check (char_length(storage_path) between 10 and 500),
  original_name text not null check (char_length(trim(original_name)) between 1 and 180),
  mime_type text not null check (mime_type in (
    'image/jpeg', 'image/png', 'image/webp', 'application/pdf'
  )),
  size_bytes bigint not null check (size_bytes between 1 and 5242880),
  uploaded_by_type text not null check (uploaded_by_type in ('customer', 'staff')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists maintenance_attachments_request_created_idx
  on public.maintenance_request_attachments(request_id, created_at desc);
create index if not exists maintenance_attachments_store_created_idx
  on public.maintenance_request_attachments(store_id, created_at desc);

create or replace function public.guard_maintenance_attachment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  request_store_id uuid;
begin
  select store_id into request_store_id
  from public.maintenance_requests
  where id = new.request_id;
  if request_store_id is null or request_store_id <> new.store_id then
    raise exception 'CLAIM_ATTACHMENT_STORE_MISMATCH';
  end if;
  new.original_name = trim(new.original_name);
  return new;
end;
$$;

drop trigger if exists maintenance_attachments_guard
on public.maintenance_request_attachments;
create trigger maintenance_attachments_guard
before insert or update on public.maintenance_request_attachments
for each row execute function public.guard_maintenance_attachment();

create or replace function public.submit_public_warranty_claim(
  target_warranty_id uuid,
  submission_id uuid,
  claim_issue text,
  claim_category text,
  claim_customer_notes text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  warranty_row public.warranties;
  existing_request public.maintenance_requests;
  created_request public.maintenance_requests;
  normalized_issue text := trim(claim_issue);
  normalized_notes text := trim(coalesce(claim_customer_notes, ''));
begin
  if submission_id is null then
    raise exception 'CLAIM_SUBMISSION_ID_REQUIRED';
  end if;
  if char_length(normalized_issue) not between 3 and 2000 then
    raise exception 'CLAIM_ISSUE_INVALID';
  end if;
  if char_length(normalized_notes) > 2000 then
    raise exception 'CLAIM_CUSTOMER_NOTES_INVALID';
  end if;
  if claim_category not in (
    'malfunction', 'battery', 'software', 'physical_damage',
    'missing_parts', 'other'
  ) then
    raise exception 'CLAIM_CATEGORY_INVALID';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(target_warranty_id::text, 0));

  select * into warranty_row
  from public.warranties
  where id = target_warranty_id
    and voided_at is null;
  if warranty_row.id is null then
    raise exception 'WARRANTY_NOT_FOUND';
  end if;
  if warranty_row.expiry_date < current_date then
    raise exception 'WARRANTY_EXPIRED';
  end if;

  select * into existing_request
  from public.maintenance_requests
  where public_submission_id = submission_id;
  if existing_request.id is not null then
    return jsonb_build_object(
      'requestId', existing_request.id,
      'storeId', existing_request.store_id,
      'claimNumber', existing_request.claim_number,
      'status', existing_request.status,
      'duplicate', true
    );
  end if;

  if (
    select count(*)
    from public.maintenance_requests request
    where request.warranty_id = target_warranty_id
      and request.channel = 'customer_portal'
      and request.created_at >= now() - interval '24 hours'
  ) >= 3 then
    raise exception 'CLAIM_RATE_LIMITED';
  end if;

  select * into existing_request
  from public.maintenance_requests request
  where request.warranty_id = target_warranty_id
    and request.channel = 'customer_portal'
    and request.status not in ('completed', 'rejected', 'cancelled')
    and lower(trim(request.issue)) = lower(normalized_issue)
    and request.created_at >= now() - interval '10 minutes'
  order by request.created_at desc
  limit 1;

  if existing_request.id is not null then
    return jsonb_build_object(
      'requestId', existing_request.id,
      'storeId', existing_request.store_id,
      'claimNumber', existing_request.claim_number,
      'status', existing_request.status,
      'duplicate', true
    );
  end if;

  insert into public.maintenance_requests (
    store_id,
    warranty_id,
    issue,
    status,
    category,
    priority,
    channel,
    customer_notes,
    public_submission_id,
    created_by
  ) values (
    warranty_row.store_id,
    warranty_row.id,
    normalized_issue,
    'new',
    claim_category,
    'normal',
    'customer_portal',
    normalized_notes,
    submission_id,
    null
  )
  returning * into created_request;

  return jsonb_build_object(
    'requestId', created_request.id,
    'storeId', created_request.store_id,
    'claimNumber', created_request.claim_number,
    'status', created_request.status,
    'duplicate', false
  );
end;
$$;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
) values (
  'claim-attachments',
  'claim-attachments',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

alter table public.maintenance_request_attachments enable row level security;

create policy maintenance_attachments_select_members
on public.maintenance_request_attachments for select to authenticated
using (public.is_store_member(store_id));

revoke all on table public.maintenance_request_attachments from anon, authenticated;
grant select on table public.maintenance_request_attachments to authenticated;

create policy claim_attachment_objects_select_members
on storage.objects for select to authenticated
using (
  bucket_id = 'claim-attachments'
  and cardinality(storage.foldername(name)) >= 2
  and (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  and public.is_store_member(((storage.foldername(name))[1])::uuid)
);

revoke all on function public.submit_public_warranty_claim(
  uuid, uuid, text, text, text
) from public;
grant execute on function public.submit_public_warranty_claim(
  uuid, uuid, text, text, text
) to service_role;

revoke all on function public.guard_maintenance_attachment() from public;
