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
- Native Kotlin/Swift owns operating-system share handoff. Android accepts `audio/*` plus `application/ogg`, copies granted `content://` data into bounded private cache, and normalizes WhatsApp-style `.opus` names to `.ogg`. iOS Runner registers as a `public.audio` document opener so the system can launch the app and deliver a file URL; a save-only Share Extension remains an App Group fallback. Both paths return a private copied path through `voicebrief/share`; widgets never parse intents or App Group defaults.
- Native calendar bridges open the platform event editor. Flutter presents and confirms the interpreted date first; neither platform performs silent calendar writes.
- UI widgets call only `AppController`. They do not call Supabase, RevenueCat, or OpenAI directly.

## Processing sequence

1. Import/record/share copies the audio into private application storage and validates extension, size, readability, and duration.
2. Production repository uploads to the private user/job path in `audio-temp`.
3. `process-audio` verifies JWT and metadata, then uses server-only RPCs to atomically reserve rounded-up customer and global service minutes before downloading the object and calling OpenAI.
4. Transcription uses the configurable `gpt-4o-mini-transcribe` default with a validated Arabic/English language hint; structured extraction uses Responses strict JSON Schema with the configurable `gpt-5.6-luna` default. The request includes the user's bounded UTC offset, anchors relative dates to the local calendar day, and deterministically normalizes explicit Arabic day/month phrases without inventing missing time details.
5. Completion moves both reservations to used minutes in one database transaction. Failure refunds the customer quota, while the service reservation is refunded only when the AI call never started. The job UUID makes retries idempotent.
6. The server object is removed in `finally`; the client removes its private copy after success/failure.
7. Result text is transient until the user taps Save, when it is stored in account-scoped Drift rows. Original audio is never stored in history.

## Trust boundaries

- Mobile contains public project/SDK identifiers only.
- RLS allows users to read their own profile, subscription, usage, jobs, and ledger; it grants no client write policy for entitlements or quota.
- Security-definer usage RPCs are callable only by `service_role`; the Edge Function passes the user ID returned by `auth.getUser`, so a mobile client cannot reserve, refund, or alter the private service budget directly.
- RevenueCat and account deletion use the service role only inside Edge Functions.

## Known platform boundary

The iOS Runner document-opening path and `VoiceBriefShare` target are wired in source, but their Swift compilation, signing, App Group entitlement, WhatsApp destination visibility, and cold/warm file delivery require macOS/Xcode plus a signed physical-device test.
