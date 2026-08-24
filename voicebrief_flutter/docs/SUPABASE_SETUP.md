# Supabase setup

## Implemented

- Versioned canonical migration and matching `supabase/schema.sql`.
- Profile, subscription state, usage periods/ledger, idempotent processing jobs, monthly service-budget records, deletion requests, and webhook replay records.
- Strict RLS read-only ownership policies; no client policy can mutate entitlement or quota.
- Private `audio-temp` bucket with 25 MB limit, audio MIME allowlist, user-scoped paths, and insert/read/delete policies.
- Atomic security-definer reserve/start/complete/fail RPCs and atomic RevenueCat event application. Usage mutation RPCs are callable only by `service_role`; the Edge Function first authenticates the bearer token and then supplies that verified user ID.
- `process-audio`, `revenuecat-webhook`, and `delete-account` functions.

## Apply and deploy

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase secrets set --env-file .env
supabase functions deploy process-audio --no-verify-jwt
supabase functions deploy delete-account --no-verify-jwt
supabase functions deploy revenuecat-webhook --no-verify-jwt
```

`--no-verify-jwt` is deliberate: the first two functions validate the bearer token explicitly with `auth.getUser`; the webhook validates a constant-time Authorization secret. Do not remove those application checks.

## Seed strategy

No production user/entitlement seed is checked in. The `auth.users` trigger creates a free lifetime period of 10 minutes. The first reservation in each UTC month atomically creates a private service budget capped at 500 audio minutes. For local testing, create users through Auth and send signed RevenueCat fixtures to the local webhook. Never seed a production Pro entitlement from the client.

## Verification

- User A cannot select User B rows or objects.
- Authenticated clients cannot call usage-mutation RPCs or update `subscription_state`, `usage_periods`, the service budget, or `usage_ledger`.
- Two concurrent reservations cannot exceed either the user quota or the private 500-minute monthly launch cap; retrying a completed job returns the stored temporary result without a second charge.
- A failed job refunds the customer quota. The service budget is refunded only if the AI call never started; once started it remains counted conservatively even if processing fails.
- Results in `processing_jobs` expire after 24 hours; schedule a daily database cleanup for expired job rows. Storage is also deleted inline; add a bucket lifecycle safety rule if available.

Common failure: an existing project may already define a trigger with the same name. Compare deliberately before applying; do not delete unrelated project schema.
