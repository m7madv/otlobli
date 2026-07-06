create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  kind text not null check (kind in ('percent', 'fixed')),
  value numeric(14, 2) not null check (value > 0),
  applies_to text not null default 'all' check (applies_to in ('all', 'shein', 'temu')),
  active boolean not null default true,
  max_uses integer,
  used_count integer not null default 0,
  min_subtotal_syp integer not null default 0,
  starts_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.coupon_redemptions (
  id uuid primary key default gen_random_uuid(),
  coupon_id uuid not null references public.coupons(id) on delete cascade,
  phone text not null,
  device_id text not null default '',
  order_id text,
  discount_syp integer not null default 0,
  created_at timestamptz not null default now()
);

create unique index if not exists coupon_redemptions_phone_uidx
  on public.coupon_redemptions (coupon_id, phone);

create unique index if not exists coupon_redemptions_device_uidx
  on public.coupon_redemptions (coupon_id, device_id)
  where device_id <> '';

alter table public.coupons enable row level security;
alter table public.coupon_redemptions enable row level security;

create or replace function public.redeem_coupon(
  p_code text,
  p_phone text,
  p_device_id text,
  p_store text,
  p_subtotal_syp integer,
  p_usd_rate numeric default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  found_coupon public.coupons%rowtype;
  rate numeric;
  discount_syp integer := 0;
begin
  if coalesce(nullif(trim(p_phone), ''), '') = '' then
    return jsonb_build_object('valid', false, 'reason', 'no_phone');
  end if;

  select *
    into found_coupon
    from public.coupons
   where lower(code) = lower(trim(p_code))
   limit 1;

  if not found then
    return jsonb_build_object('valid', false, 'reason', 'not_found');
  end if;
  if not found_coupon.active then
    return jsonb_build_object('valid', false, 'reason', 'inactive');
  end if;
  if found_coupon.starts_at is not null and found_coupon.starts_at > now() then
    return jsonb_build_object('valid', false, 'reason', 'not_started');
  end if;
  if found_coupon.expires_at is not null and found_coupon.expires_at < now() then
    return jsonb_build_object('valid', false, 'reason', 'expired');
  end if;
  if found_coupon.applies_to <> 'all' and found_coupon.applies_to <> lower(coalesce(p_store, '')) then
    return jsonb_build_object('valid', false, 'reason', 'wrong_store');
  end if;
  if coalesce(p_subtotal_syp, 0) < found_coupon.min_subtotal_syp then
    return jsonb_build_object('valid', false, 'reason', 'below_min');
  end if;
  if found_coupon.max_uses is not null and found_coupon.used_count >= found_coupon.max_uses then
    return jsonb_build_object('valid', false, 'reason', 'exhausted');
  end if;

  if found_coupon.kind = 'percent' then
    discount_syp := floor(coalesce(p_subtotal_syp, 0) * least(greatest(found_coupon.value, 0), 100) / 100.0);
  else
    select value::numeric
      into rate
      from public.app_settings
     where key = 'usd_to_syp_rate';
    rate := coalesce(p_usd_rate, rate, 13000);
    discount_syp := floor(found_coupon.value * rate);
  end if;

  if discount_syp < 0 then
    discount_syp := 0;
  end if;
  if discount_syp > coalesce(p_subtotal_syp, 0) then
    discount_syp := coalesce(p_subtotal_syp, 0);
  end if;

  begin
    insert into public.coupon_redemptions (coupon_id, phone, device_id, discount_syp)
    values (
      found_coupon.id,
      trim(p_phone),
      coalesce(nullif(trim(p_device_id), ''), ''),
      discount_syp
    );
  exception when unique_violation then
    return jsonb_build_object('valid', false, 'reason', 'already_used');
  end;

  update public.coupons
     set used_count = used_count + 1
   where id = found_coupon.id;

  return jsonb_build_object(
    'valid', true,
    'discountSyp', discount_syp,
    'code', found_coupon.code,
    'kind', found_coupon.kind
  );
end;
$$;

revoke all on function public.redeem_coupon(text, text, text, text, integer, numeric) from public;
grant execute on function public.redeem_coupon(text, text, text, text, integer, numeric) to anon, authenticated;
