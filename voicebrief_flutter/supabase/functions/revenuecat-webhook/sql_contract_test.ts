const migrationDirectory = "supabase/migrations";
const monthlyMigration = await Deno.readTextFile(
  `${migrationDirectory}/20260902010000_monthly_subscription_quota.sql`,
);
const specialEventsMigration = await Deno.readTextFile(
  `${migrationDirectory}/20260902011000_revenuecat_special_events.sql`,
);
const schema = await Deno.readTextFile("supabase/schema.sql");

function assert(condition: boolean, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function assertInOrder(source: string, fragments: string[]): void {
  let cursor = -1;
  for (const fragment of fragments) {
    const next = source.indexOf(fragment, cursor + 1);
    assert(next > cursor, `missing/out-of-order SQL fragment: ${fragment}`);
    cursor = next;
  }
}

Deno.test("quota migration drains runtime writers before altering state", () => {
  assertInOrder(monthlyMigration, [
    "lock table public.revenuecat_webhook_events in share row exclusive mode",
    "lock table public.processing_jobs in exclusive mode",
    "lock table public.subscription_state in share row exclusive mode",
    "lock table public.usage_periods in share row exclusive mode",
    "lock table public.usage_ledger in share row exclusive mode",
    "alter table public.subscription_state",
    "alter table public.usage_periods",
  ]);
});

Deno.test("quota migration preserves a future state period and its bridge", () => {
  assertInOrder(monthlyMigration, [
    "raise exception 'ambiguous_legacy_subscription_state_period'",
    "up.ends_at = ss.expires_at",
    "or (up.starts_at <= now() and up.ends_at > now())",
    "v_is_state_period := v_legacy.ends_at = v_state_expires_at",
    "if v_is_state_period then",
    "set quota_generation_key = v_generation_key",
    "raise exception 'legacy_subscription_generation_backfill_failed'",
  ]);
});

Deno.test("stale transfer still merges the matching generation high-water", () => {
  const contract = [
    "v_should_merge_usage := p_is_pro and (",
    "v_state_applied > 0",
    "and entitlement = 'pro'",
    "and quota_generation_key = v_generation_key",
    "if v_should_merge_usage then",
    "used_minutes = greatest(",
  ];
  for (const source of [specialEventsMigration, schema]) {
    assertInOrder(source, contract);
  }
});

Deno.test("transfer sums only proven parallel legacy grants", () => {
  const contract = [
    "v_has_parallel_generation_grants boolean",
    "user_id = p_destination_user_id",
    "user_id = any(v_source_user_ids)",
    "and quota_generation_key = v_generation_key",
    "when v_has_parallel_generation_grants",
    "then sum(per_user.used_minutes)",
    "else max(per_user.used_minutes)",
  ];
  for (const source of [specialEventsMigration, schema]) {
    assertInOrder(source, contract);
  }
});

Deno.test("subscription sync limiter remains service-role only", () => {
  const contract = [
    "create table if not exists public.subscription_sync_rate_limits",
    "create or replace function public.claim_voicebrief_subscription_sync(",
    "request_count < 6",
    "revoke all on function public.claim_voicebrief_subscription_sync(uuid)",
    "grant execute on function public.claim_voicebrief_subscription_sync(uuid)",
    "to service_role",
  ];
  assertInOrder(specialEventsMigration, contract);
  assert(
    schema.includes("create table public.subscription_sync_rate_limits"),
    "canonical schema is missing the rate-limit table",
  );
  for (const source of [monthlyMigration, specialEventsMigration, schema]) {
    assert(
      source.includes(
        "grant execute on function public.voicebrief_subscription_generation_key",
      ),
      "service role cannot compute the canonical subscription generation",
    );
  }
});
