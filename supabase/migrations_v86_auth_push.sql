-- ============================================================================
-- otlobli v86 — دخول جوجل (ربط هوية) + إشعارات Push
-- كل ما هنا "إضافي" وآمن: جداول/دوال جديدة فقط. لا يمسّ أي جدول أو دالة قائمة.
-- المرتكز يبقى رقم الهاتف (customers.phone). جوجل = هوية مربوطة بحساب مرتكز على الهاتف.
-- طبّقه عبر: supabase db query --linked -f supabase/migrations_v86_auth_push.sql
-- ============================================================================

-- ── 1) جدول هويّات تسجيل الدخول (جوجل الآن، قابل للتوسّع) ───────────────────
create table if not exists public.customer_identities (
  id               uuid primary key default gen_random_uuid(),
  customer_id      uuid not null references public.customers(id) on delete cascade,
  provider         text not null check (provider in ('google')),
  provider_user_id text not null,
  email            text,
  email_verified   boolean not null default false,
  display_name     text,
  created_at       timestamptz not null default now(),
  last_login_at    timestamptz,
  unique (provider, provider_user_id)
);

create index if not exists idx_customer_identities_customer on public.customer_identities(customer_id);
create index if not exists idx_customer_identities_email    on public.customer_identities(lower(email));

-- ── 2) جدول رموز أجهزة الإشعارات (FCM / APNs) ──────────────────────────────
create table if not exists public.device_tokens (
  id          uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  phone       text not null,
  platform    text not null check (platform in ('android','ios','web')),
  token       text not null,
  device_id   text,
  enabled     boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (token)
);

create index if not exists idx_device_tokens_customer on public.device_tokens(customer_id);
create index if not exists idx_device_tokens_phone    on public.device_tokens(phone);
create index if not exists idx_device_tokens_enabled  on public.device_tokens(customer_id) where enabled;

-- RLS: لا وصول مباشر من anon/authenticated؛ كل شي عبر دوال SECURITY DEFINER أو service_role.
alter table public.customer_identities enable row level security;
alter table public.device_tokens       enable row level security;

-- ── 3) إصدار جلسة لعميل موجود عبر معرّفه (يُستخدم بعد التحقق من جوجل) ────────
-- يعكس منطق create_customer_session لكن مرتكزه customer_id بدل الهاتف.
create or replace function public.create_customer_session_for_customer(
  p_customer_id uuid,
  p_token_hash  text,
  p_expires_at  timestamptz
) returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  target_phone text;
  new_session_id uuid;
begin
  if coalesce(p_token_hash, '') !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid token hash';
  end if;
  if p_expires_at is null or p_expires_at <= now() or p_expires_at > now() + interval '90 days' then
    raise exception 'invalid session expiry';
  end if;

  select phone into target_phone
  from public.customers
  where id = p_customer_id
  limit 1;

  if target_phone is null then
    raise exception 'customer not found';
  end if;

  delete from public.customer_sessions
  where expires_at <= now() or revoked_at is not null;

  insert into public.customer_sessions (customer_id, phone, token_hash, expires_at)
  values (p_customer_id, target_phone, p_token_hash, p_expires_at)
  returning id into new_session_id;

  return new_session_id;
end;
$$;

-- ── 4) البحث عن هوية جوجل → إرجاع بيانات العميل (لخادم الحافة، service_role) ──
create or replace function public.find_identity_customer(
  p_provider         text,
  p_provider_user_id text
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  result jsonb;
begin
  select jsonb_build_object(
    'customer_id', c.id,
    'phone', c.phone,
    'name', c.name
  ) into result
  from public.customer_identities ci
  join public.customers c on c.id = ci.customer_id
  where ci.provider = p_provider
    and ci.provider_user_id = p_provider_user_id
  limit 1;

  return result; -- null إن لم توجد
end;
$$;

-- ── 5) ربط هوية جوجل بالعميل المصادَق عليه عبر جلسته الحالية ────────────────
-- يُستدعى: (أ) من مستخدم مسجّل بالهاتف يربط جوجل من الإعدادات، أو
--          (ب) بعد أن يوثّق مستخدمُ جوجل هاتفَه لأول مرة عبر OTP.
create or replace function public.link_customer_identity(
  p_session_token    text,
  p_provider         text,
  p_provider_user_id text,
  p_email            text,
  p_email_verified   boolean,
  p_display_name     text
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  session_customer_id uuid;
  existing_customer_id uuid;
begin
  if p_provider is null or p_provider not in ('google') then
    raise exception 'invalid provider';
  end if;
  if coalesce(p_provider_user_id, '') = '' then
    raise exception 'invalid provider user id';
  end if;

  -- يتحقق من الجلسة ويعيد customer_id، وإلا يرمي استثناء.
  session_customer_id := public.require_customer_session(p_session_token, null);

  -- إن كانت الهوية مربوطة أصلاً بعميل مختلف → امنع الاختطاف.
  select customer_id into existing_customer_id
  from public.customer_identities
  where provider = p_provider and provider_user_id = p_provider_user_id
  limit 1;

  if existing_customer_id is not null and existing_customer_id <> session_customer_id then
    raise exception 'identity already linked to another account';
  end if;

  insert into public.customer_identities
    (customer_id, provider, provider_user_id, email, email_verified, display_name, last_login_at)
  values
    (session_customer_id, p_provider, p_provider_user_id, p_email, coalesce(p_email_verified, false), p_display_name, now())
  on conflict (provider, provider_user_id)
  do update set
    email = excluded.email,
    email_verified = excluded.email_verified,
    display_name = excluded.display_name,
    last_login_at = now();

  return jsonb_build_object('customer_id', session_customer_id, 'linked', true);
end;
$$;

-- ── 6) تحديث last_login_at لهوية (لخادم الحافة عند تسجيل دخول ناجح) ─────────
create or replace function public.touch_identity_login(
  p_provider         text,
  p_provider_user_id text
) returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  update public.customer_identities
  set last_login_at = now()
  where provider = p_provider and provider_user_id = p_provider_user_id;
end;
$$;

-- ── 7) حفظ/تحديث رمز جهاز الإشعارات (مصادَق عليه بجلسة العميل) ──────────────
create or replace function public.upsert_device_token(
  p_session_token text,
  p_platform      text,
  p_token         text,
  p_device_id     text
) returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  session_customer_id uuid;
  session_phone text;
begin
  if p_platform is null or p_platform not in ('android','ios','web') then
    raise exception 'invalid platform';
  end if;
  if coalesce(p_token, '') = '' then
    raise exception 'invalid token';
  end if;

  session_customer_id := public.require_customer_session(p_session_token, null);

  select phone into session_phone
  from public.customers where id = session_customer_id limit 1;

  insert into public.device_tokens (customer_id, phone, platform, token, device_id, enabled, updated_at)
  values (session_customer_id, coalesce(session_phone, ''), p_platform, p_token, p_device_id, true, now())
  on conflict (token) do update set
    customer_id = excluded.customer_id,
    phone = excluded.phone,
    platform = excluded.platform,
    device_id = excluded.device_id,
    enabled = true,
    updated_at = now();
end;
$$;

-- ── 8) تعطيل رمز جهاز (يُستدعى من خادم الإرسال عند رفض FCM/APNs للرمز) ───────
create or replace function public.disable_device_token(p_token text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  update public.device_tokens set enabled = false, updated_at = now()
  where token = p_token;
end;
$$;

-- ── 9) صلاحيات التنفيذ ─────────────────────────────────────────────────────
-- الدوال المرتكزة على الجلسة يستدعيها التطبيق بمفتاح anon.
grant execute on function public.link_customer_identity(text,text,text,text,boolean,text) to anon, authenticated;
grant execute on function public.upsert_device_token(text,text,text,text)                 to anon, authenticated;
-- الدوال الإدارية/الخلفية تبقى لـ service_role فقط (الافتراضي يمنع anon).
revoke all on function public.create_customer_session_for_customer(uuid,text,timestamptz) from anon, authenticated;
revoke all on function public.find_identity_customer(text,text)                          from anon, authenticated;
revoke all on function public.touch_identity_login(text,text)                            from anon, authenticated;
revoke all on function public.disable_device_token(text)                                 from anon, authenticated;
