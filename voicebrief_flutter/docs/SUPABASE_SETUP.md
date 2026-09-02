# Supabase setup

## Implemented

- Versioned canonical migration and matching `supabase/schema.sql`.
- Profile, subscription state, usage periods/ledger, idempotent processing jobs, monthly service-budget records, deletion requests, and webhook replay records.
- Strict RLS read-only ownership policies; no client policy can mutate entitlement or quota.
- Private `audio-temp` bucket with 25 MB limit, audio MIME allowlist, and user-scoped read/delete policies. Direct authenticated insertion is denied; `create-audio-upload` issues one exact signed upload after an atomic reservation. Retry issuance closes two hours after reservation creation, and a database constraint caps the reservation at four hours from creation so retries cannot slide cleanup indefinitely.
- Atomic security-definer reserve/start/complete/fail RPCs and atomic RevenueCat event application. Usage mutation RPCs are callable only by `service_role`; the Edge Function first authenticates the bearer token and then supplies that verified user ID.
- `sync-subscription` is guarded by a database-atomic, service-role-only limit of six claims per user per minute before any RevenueCat API call. It cannot grant a new Pro generation from client input; only the signed webhook/`TRANSFER` path can do so.
- `create-audio-upload`, `process-audio`, `cleanup-expired-audio`, `revenuecat-webhook`, authenticated `sync-subscription`, `delete-account`, and `legal` functions.
- Independent abandoned-audio cleanup through `pg_cron`/`pg_net`: an RPC atomically leases at most 100 reservations that expired at least 15 minutes earlier, and the Edge Function removes their exact paths through `storage.from('audio-temp').remove(...)`. The first successful removal retains a non-active tombstone; after at least another 15 minutes a second claim repeats removal, then retires only the matching rows. This preserves a verification pointer through a tested delayed-upload race instead of assuming one removal is final. A failed deletion releases the claim; a crashed invocation becomes retryable after 30 minutes.

## Apply and deploy

```bash
supabase login
supabase link --project-ref jyehqpdbayslhzebdycj
supabase secrets set --env-file .env
supabase functions deploy cleanup-expired-audio --no-verify-jwt
supabase db push
supabase functions deploy create-audio-upload --no-verify-jwt
supabase functions deploy process-audio --no-verify-jwt
supabase functions deploy delete-account --no-verify-jwt
supabase functions deploy revenuecat-webhook --no-verify-jwt
supabase functions deploy sync-subscription --no-verify-jwt
supabase functions deploy legal --no-verify-jwt
```

The project ref above is intentionally explicit. Never link or deploy this source to Damanak `exxayzlklvgeyqhvtzgi` or to `talabieh`.

`--no-verify-jwt` is deliberate. User functions validate the bearer token explicitly with `auth.getUser`; the cleanup function validates an `apikey` against Supabase's current secret-key dictionary (with temporary legacy `service_role` compatibility); the webhook validates a constant-time Authorization secret. Do not remove those application checks.

## Independent audio cleanup activation

Before applying `20260830230000_independent_audio_cleanup.sql`, use the Supabase Dashboard for the VoiceBrief project only:

1. In **Settings → API Keys**, create a dedicated current-format secret key for cleanup automation. Do not put it in source, a Flutter define, a terminal command, or logs. A legacy `service_role` key remains compatible only as a migration fallback.
2. In **Vault**, create `voicebrief_project_url` with the exact project API URL and `voicebrief_secret_key` with that dedicated secret key. The migration reads only these named Vault entries.
3. Deploy `cleanup-expired-audio`, apply the migration, then immediately deploy the updated `create-audio-upload` as shown above. The cron job `voicebrief-expired-audio-cleanup` invokes the function every 15 minutes.
4. Verify the job exists and is active, inspect `cron.job_run_details` and the Edge Function's count-only logs, and run a synthetic expired-reservation test. Confirm that the first pass removes the object but keeps a staged tombstone, then that a later pass repeats removal and retires the reservation while an unexpired control object remains. Also confirm a matching retry before two hours succeeds, a retry at/after two hours returns cleanup pending, and no row can set `expires_at` beyond `created_at + 4 hours`.

Never delete from `storage.objects`: Supabase documents that SQL deletion removes metadata without deleting the underlying object. This implementation treats Storage tables as read-only and deletes only via the public Storage API. The cleanup migration and function are currently local source changes; they have not been deployed by this task.

## RevenueCat account deletion

Before deploying the build 18 `delete-account` function, create a private, project-wide RevenueCat secret API key and store it only as the Supabase Edge secret `REVENUECAT_SECRET_API_KEY`. The backend uses it to read current Customer Info for sparse webhook events and to delete the RevenueCat customer during account deletion; the mobile public SDK keys are not valid for either operation, and the private key must never be bundled in Flutter. A `200` or `404` RevenueCat delete response is treated as idempotent success; any other failure stops before Supabase Auth, database, or Storage deletion begins. Deploy migration `20260830234000_revenuecat_account_deletion.sql` and the matching `revenuecat-webhook` together so late events are anonymized instead of recreating state for a deleted user.

## Seed strategy

No production user/entitlement seed is checked in. The `auth.users` trigger creates a free lifetime period of 10 minutes. The first reservation in each UTC month atomically creates a private service budget capped at 500 audio minutes. For local testing, create users through Auth and send signed RevenueCat fixtures to the local webhook. Never seed a production Pro entitlement from the client.

## Verification

- User A cannot select User B rows or objects.
- Authenticated clients cannot call usage-mutation RPCs or update `subscription_state`, `usage_periods`, the service budget, or `usage_ledger`.
- Two concurrent reservations cannot exceed either the user quota or the private 500-minute monthly launch cap; retrying a completed job returns the stored temporary result without a second charge.
- A failed job refunds the customer quota. The service budget is refunded only if the AI call never started; once started it remains counted conservatively even if processing fails.
- Results in `processing_jobs` expire after 24 hours and the existing database cron redacts/refunds them every 15 minutes. Storage deletion is attempted inline after processing. Any expired upload reservation that remains is handled by the new two-pass scheduled Edge Function after its Vault-backed deployment and live verification.

Common failure: an existing project may already define a trigger with the same name. Compare deliberately before applying; do not delete unrelated project schema.
