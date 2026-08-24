# Security review

Reviewed: 2026-08-24. No critical or high-severity source finding remains after the fixes below.

## Controls verified

- No OpenAI key, service-role key, webhook secret, private OAuth key, or signing key appears in mobile configuration. Ignore rules cover common local secret/signing files.
- OpenAI endpoints exist only in `supabase/functions/process-audio`.
- Supabase RLS exposes own-row reads only; entitlement/quota/service-budget writes have no client policy. Usage mutation functions are `service_role`-only and receive the user ID only after the Edge Function verifies the caller's JWT.
- Customer and global service minutes are reserved/charged/refunded atomically with row locks and checks; job UUID prevents duplicate charge/processing. The private monthly launch cap is 500 audio minutes.
- RevenueCat Authorization uses constant-time comparison; events are replay-idempotent and older events cannot roll state backward.
- Audio path must exactly match authenticated `user/job/input.extension`; extension/MIME/size/duration are checked in client, Storage policy, Edge Function, and downloaded blob.
- Android accepts only `audio/*`, uses `ContentResolver`, copies to private cache with a bounded loop, closes resources, and avoids broad storage permission.
- A real Ogg/Opus fixture delivered by an exported test `ContentProvider` passed cold- and warm-start imports on API 35 and physical Android 9. The temporary provider package was removed from both devices after testing.
- iOS extension accepts `public.audio`, uses one attachment, enforces size, copies to App Group, and avoids prohibited host-app APIs.
- Remote audio deletion runs in `finally`; client temp deletion runs after processing/failure. Content and sensitive identifiers are excluded from logs.
- Account deletion authenticates the user, removes temporary Storage, deletes the Auth user (cascading database data), then client clears account-scoped local history.
- Deep-link handlers use the single `voicebrief` scheme; production should add host/path allowlists if more routes or universal links are introduced.

## Findings fixed during implementation

- Nested Freezed result objects originally did not serialize to JSON maps; explicit nested serialization now protects Drift/idempotency storage.
- RevenueCat replay handling originally lacked event-time ordering; atomic application now records event time and rejects state rollback by older deliveries.
- Narrow/large-text component overflows were fixed rather than clipped.
- Legacy end-of-life SQLite Flutter bundle dependencies were removed from the resolved graph.
- Android share-copy failures now propagate a generic user-safe error instead of failing silently, while partial files and sensitive URI details remain discarded.
- Supabase Edge Functions now use per-function `deno.json` files with `@supabase/supabase-js` pinned to `2.112.4`; Deno formatting, lint, and type checks pass.
- Client-callable usage mutation RPCs were removed. A server-only `ai_started` transition ensures failed AI attempts still count against the conservative service budget while pre-AI validation failures do not.
- A live anonymous REST probe found Supabase's explicit default function grants still allowed `anon` to enter the reservation function after revoking only `public`. Migration `20260824020000_lock_server_rpc_permissions.sql` now revokes `public`, `anon`, and `authenticated` explicitly from every server RPC; the follow-up probe must fail at permission evaluation before input validation.
- User-local time-zone offset is accepted only as a finite integer from `-840` through `840`; it supplies date context and is not trusted as authorization data.
- Free-tier Gemini is not a processor for VoiceBrief content because Google's unpaid-services terms allow content use for product/ML improvement. The production path remains OpenAI behind the Edge Function; no AI credential exists in the app bundle.
- Public support writes run only through the `legal` Edge Function. Client roles have no table privileges; the function validates lengths/category/email, uses a honeypot, stores only a salted network hash for rate limiting, and caps one network to five requests per 24 hours.
- Android release signing fails closed unless the private upload key is supplied. The key and DPAPI-encrypted credential live outside Git with restricted ACLs, and build-time secret variables are cleared in `finally`.

## Remaining operational risks/gates

- Three migrations and four functions are deployed to the independent live VoiceBrief project. A dedicated OpenAI service-account key is stored only as a Supabase secret. A live synthetic-audio test passed transcription, strict structured output, date resolution, remote audio cleanup, and temporary account deletion; the ledger ended at one used and zero reserved minute.
- Add a scheduled cleanup for expired 24-hour `processing_jobs` and a Storage lifecycle safety net.
- Run dependency/SBOM/vulnerability scanning in CI and review advisories before release.
- Pen-test OAuth redirect, webhook configuration, signed entitlements, and hostile content providers/extensions on release builds.
- Confirm the production-candidate IDs in both stores, back up the upload key/password separately, obtain owner approval of the live legal drafts, and configure OAuth/RevenueCat/Apple signing.

Do not log request/response bodies while diagnosing these systems.
