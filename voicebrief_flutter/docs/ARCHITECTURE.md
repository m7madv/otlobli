# Architecture

VoiceBrief uses pragmatic feature-first MVVM with one-way state flow.

```text
Screen → AppController (StateNotifier) → repository interface → fake or production service
                                              ↓
                                      typed Freezed models
                                              ↓
                                     Drift local history
```

## Mobile boundaries

- `lib/app`: bootstrap, typed configuration, providers, router, and shared application state.
- `lib/core`: typed failures, safe logging, Drift database, validation, formatting, and quota math.
- `lib/features`: domain/data/presentation code grouped by product feature.
- `lib/ui/core`: design tokens, themes, and reusable components.
- Native Kotlin/Swift owns operating-system share handoff. Android accepts `audio/*` plus `application/ogg`, copies granted `content://` data into bounded private cache, and normalizes WhatsApp-style `.opus` names to `.ogg`. iOS Runner remains a `public.audio` document opener where the source supports document-open. For Share Extension-only sources, the extension copies bounded audio, uses the Runner-synchronized Supabase session from the private App Group, and processes through the same Storage/Edge Function contract while the extension remains open. App Group sessions and processed manifests are bound to both user ID and a rotating generation; logout/account switch invalidates the generation and clears payloads. On success it atomically persists the processed result, schedules an authorized local ready notification, deletes local audio, and completes the extension. Notification selection marks the handoff for immediate `/result` navigation without a second upload or charge.
- Native calendar bridges open the platform event editor. Flutter presents and confirms the interpreted date first; neither platform performs silent calendar writes.
- The reminder bridge uses AlarmKit for a real one-shot system alarm on iOS 26.1+, after the dedicated permission prompt declared by `NSAlarmKitUsageDescription`. iOS 14–26.0 keep a local-notification fallback, while Android delegates to `AlarmClock.ACTION_SET_ALARM`. AlarmKit alarms belong to VoiceBrief and are not inserted into Apple's Clock app.
- UI widgets call only `AppController`. They do not call Supabase, RevenueCat, or OpenAI directly.

## Processing sequence

1. Import/record/share copies the audio into private application storage and validates extension, size, readability, and duration.
2. Production repository requests `create-audio-upload`, which atomically reserves a bounded exact path/size/MIME and returns a short-lived signed upload token; direct authenticated object insertion is disabled.
3. `process-audio` verifies JWT plus the live upload reservation, downloads the exact object, parses media metadata server-side, rejects forged duration estimates, then uses server-only RPCs to atomically reserve rounded-up customer and global service minutes before calling OpenAI.
4. Transcription uses the configurable `gpt-4o-mini-transcribe` default with a validated Arabic/English language hint; structured extraction uses Responses strict JSON Schema with the configurable `gpt-5.6-luna` default. The request includes the user's bounded UTC offset, anchors relative dates to the local calendar day, and deterministically normalizes explicit Arabic day/month phrases without inventing missing time details.
5. Completion moves both reservations to used minutes in one database transaction. Failure refunds the customer quota, while the service reservation is refunded only when the AI call never started. The job UUID makes retries idempotent.
6. The server object is removed in `finally`; the client removes its private copy after success/failure.
7. Result text created in Runner is transient until the user taps Save. A successful iOS Share Extension result is persisted automatically as a processed-result handoff so the ready notification can open it; Runner then stores it in the same account-scoped Drift history. Original audio is never stored in history.

## Trust boundaries

- Mobile contains public project/SDK identifiers only.
- RLS allows users to read their own profile, subscription, usage, jobs, and ledger; it grants no client write policy for entitlements or quota.
- Security-definer usage RPCs are callable only by `service_role`; the Edge Function passes the user ID returned by `auth.getUser`, so a mobile client cannot reserve, refund, or alter the private service budget directly.
- RevenueCat and account deletion use the service role only inside Edge Functions.

## Known platform boundary

Apple does not provide a public API for a Share Extension to launch its containing iOS app. Builds 9 and 10 physically confirmed that boundary for WhatsApp. Build 12 processes within the extension, then uses Apple's supported local-notification interaction to let the user launch Runner after completion. Notification authorization, scheduling from the signed extension, tap routing, shared-session refresh, live network completion, dated-result display, and cancellation still require signed physical-device acceptance.
