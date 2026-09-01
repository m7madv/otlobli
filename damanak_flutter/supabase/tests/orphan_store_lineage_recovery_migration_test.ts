import { PGlite } from "npm:@electric-sql/pglite@0.3.14";

const migrationUrl = new URL(
  "../migrations/20260901012000_damanak_orphan_store_lineage_recovery.sql",
  import.meta.url,
);
const liveContractUrl = new URL(
  "./orphan_store_lineage_recovery_live.sql",
  import.meta.url,
);
const schemaUrl = new URL("../schema.sql", import.meta.url);

function receiptApplyFunction(sql: string) {
  const startMarker =
    "create function public.apply_verified_store_entitlement_with_receipt(";
  const start = sql.indexOf(startMarker);
  const end = sql.indexOf("\n$$;", start);
  if (start < 0 || end < 0) {
    throw new Error("receipt-aware entitlement function is missing");
  }
  return sql.slice(start, end + 4).replaceAll("\r\n", "\n");
}

const minimalSupabaseSchema = String.raw`
create schema auth;
create schema extensions;
create schema private;
create role anon;
create role authenticated;
create role service_role;

create function auth.role()
returns text language sql stable
as $$ select 'service_role'::text $$;

create function extensions.gen_random_uuid()
returns uuid language sql volatile
as $$ select pg_catalog.gen_random_uuid() $$;

-- PGlite does not bundle pgcrypto. This deterministic 32-byte stand-in keeps
-- the migration's hash equality and collision guards executable in a real
-- PostgreSQL engine; production/live tests continue to use pgcrypto SHA-256.
create function extensions.digest(input text, algorithm text)
returns bytea language sql immutable
as $$
  select pg_catalog.decode(
    pg_catalog.md5(input) || pg_catalog.md5(input),
    'hex'
  )
$$;

create table auth.users (
  id uuid primary key,
  aud text,
  role text,
  email text,
  encrypted_password text,
  email_confirmed_at timestamptz,
  raw_app_meta_data jsonb,
  raw_user_meta_data jsonb,
  created_at timestamptz,
  updated_at timestamptz
);

create table public.stores (
  id uuid primary key,
  name text not null,
  owner_id uuid not null references auth.users(id),
  country_code text,
  currency_code text
);

create table public.store_members (
  store_id uuid not null references public.stores(id),
  user_id uuid not null references auth.users(id),
  role text not null,
  status text not null,
  primary key (store_id, user_id)
);

create table public.store_entitlements (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  store_id uuid not null references public.stores(id),
  user_id uuid references auth.users(id),
  platform text not null,
  product_id text not null,
  base_plan_id text not null,
  plan_id text not null,
  billing_cycle text not null,
  transaction_id text not null,
  original_transaction_id text not null,
  status text not null,
  environment text not null,
  period_start timestamptz,
  period_end timestamptz,
  auto_renews boolean not null,
  superseded_at timestamptz,
  unique (platform, original_transaction_id)
);

create table public.subscriptions (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  store_id uuid not null unique references public.stores(id),
  plan_id text not null,
  status text not null,
  source text not null,
  billing_provider text,
  store_product_id text,
  billing_cycle text,
  original_transaction_id text,
  auto_renews boolean not null,
  current_period_start timestamptz,
  current_period_end timestamptz,
  store_environment text,
  store_entitlement_id uuid references public.store_entitlements(id)
);

create table private.store_receipt_secrets (
  platform text not null,
  original_transaction_id text not null,
  purchase_token text not null,
  updated_at timestamptz not null,
  primary key (platform, original_transaction_id)
);

create table private.google_purchase_token_links (
  token_hash text primary key,
  linked_token_hash text,
  platform text not null default 'google_play',
  store_id uuid not null references public.stores(id),
  user_id uuid references auth.users(id),
  original_transaction_id text not null,
  first_seen_at timestamptz not null default pg_catalog.now(),
  last_seen_at timestamptz not null default pg_catalog.now(),
  foreign key (platform, original_transaction_id)
    references public.store_entitlements(platform, original_transaction_id)
);

create function public.apply_verified_store_entitlement(
  target_store_id uuid,
  target_user_id uuid,
  billing_platform text,
  billed_product_id text,
  billed_base_plan_id text,
  external_transaction_id text,
  external_original_transaction_id text,
  entitlement_status text,
  store_environment text,
  entitlement_period_start timestamptz,
  entitlement_period_end timestamptz,
  entitlement_auto_renews boolean
)
returns public.subscriptions
language plpgsql
security definer
set search_path = ''
as $$
declare
  entitlement_id uuid := pg_catalog.gen_random_uuid();
  result public.subscriptions%rowtype;
begin
  insert into public.store_entitlements (
    id,
    store_id,
    user_id,
    platform,
    product_id,
    base_plan_id,
    plan_id,
    billing_cycle,
    transaction_id,
    original_transaction_id,
    status,
    environment,
    period_start,
    period_end,
    auto_renews
  ) values (
    entitlement_id,
    target_store_id,
    target_user_id,
    billing_platform,
    billed_product_id,
    billed_base_plan_id,
    split_part(billed_product_id, '.', 4),
    billed_base_plan_id,
    external_transaction_id,
    external_original_transaction_id,
    entitlement_status,
    store_environment,
    entitlement_period_start,
    entitlement_period_end,
    entitlement_auto_renews
  );

  insert into public.subscriptions (
    store_id,
    plan_id,
    status,
    source,
    billing_provider,
    store_product_id,
    billing_cycle,
    original_transaction_id,
    auto_renews,
    current_period_start,
    current_period_end,
    store_environment,
    store_entitlement_id
  ) values (
    target_store_id,
    split_part(billed_product_id, '.', 4),
    case when entitlement_status in ('active', 'grace')
      then 'active' else 'canceled' end,
    'store',
    billing_platform,
    billed_product_id,
    billed_base_plan_id,
    external_original_transaction_id,
    entitlement_auto_renews,
    entitlement_period_start,
    entitlement_period_end,
    store_environment,
    entitlement_id
  )
  on conflict (store_id) do update set
    plan_id = excluded.plan_id,
    status = excluded.status,
    source = excluded.source,
    billing_provider = excluded.billing_provider,
    store_product_id = excluded.store_product_id,
    billing_cycle = excluded.billing_cycle,
    original_transaction_id = excluded.original_transaction_id,
    auto_renews = excluded.auto_renews,
    current_period_start = excluded.current_period_start,
    current_period_end = excluded.current_period_end,
    store_environment = excluded.store_environment,
    store_entitlement_id = excluded.store_entitlement_id;

  select * into result
  from public.subscriptions subscription
  where subscription.store_id = target_store_id;
  return result;
end;
$$;
`;

Deno.test("orphan lineage migration applies and passes its SQL contract", async () => {
  const database = new PGlite();
  try {
    const migration = await Deno.readTextFile(migrationUrl);
    const schema = await Deno.readTextFile(schemaUrl);
    if (receiptApplyFunction(migration) !== receiptApplyFunction(schema)) {
      throw new Error("schema receipt RPC diverged from the migration");
    }
    await database.exec(minimalSupabaseSchema);
    await database.exec(migration);
    await database.exec(await Deno.readTextFile(liveContractUrl));
  } finally {
    await database.close();
  }
});
