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
- Native Kotlin/Swift owns operating-system share handoff. Android accepts `audio/*` plus `application/ogg`, copies granted `content://` data into bounded private cache, and normalizes WhatsApp-style `.opus` names to `.ogg`. iOS Runner remains a `public.audio` document opener where the source supports document-open. For Share Extension-only sources, the extension copies bounded audio, uses the Runner-synchronized Supabase session from the private App Group, processes the file through the same Storage/Edge Function contract, and displays the result without attempting to launch Runner. A user-confirmed processed-result manifest later enters Flutter through `voicebrief/share` without a second upload or charge.
- Native calendar bridges open the platform event editor. Flutter presents and confirms the interpreted date first; neither platform performs silent calendar writes.
- UI widgets call only `AppController`. They do not call Supabase, RevenueCat, or OpenAI directly.

## Processing sequence

1. Import/record/share copies the audio into private application storage and validates extension, size, readability, and duration.
2. Production repository uploads to the private user/job path in `audio-temp`.
3. `process-audio` verifies JWT and metadata, then uses server-only RPCs to atomically reserve rounded-up customer and global service minutes before downloading the object and calling OpenAI.
4. Transcription uses the configurable `gpt-4o-mini-transcribe` default with a validated Arabic/English language hint; structured extraction uses Responses strict JSON Schema with the configurable `gpt-5.6-luna` default. The request includes the user's bounded UTC offset, anchors relative dates to the local calendar day, and deterministically normalizes explicit Arabic day/month phrases without inventing missing time details.
5. Completion moves both reservations to used minutes in one database transaction. Failure refunds the customer quota, while the service reservation is refunded only when the AI call never started. The job UUID makes retries idempotent.
6. The server object is removed in `finally`; the client removes its private copy after success/failure.
7. Result text is transient until the user taps Save. In Runner it is then stored in account-scoped Drift rows; in the iOS Share Extension `Save in VoiceBrief` writes a processed-result handoff that Runner later stores in the same account-scoped history. Original audio is never stored in history.

## Trust boundaries

- Mobile contains public project/SDK identifiers only.
- RLS allows users to read their own profile, subscription, usage, jobs, and ledger; it grants no client write policy for entitlements or quota.
- Security-definer usage RPCs are callable only by `service_role`; the Edge Function passes the user ID returned by `auth.getUser`, so a mobile client cannot reserve, refund, or alter the private service budget directly.
- RevenueCat and account deletion use the service role only inside Edge Functions.

## Known platform boundary

Apple does not provide a public API for a Share Extension to launch its containing iOS app. Builds 9 and 10 physically confirmed that boundary for WhatsApp. Build 11 therefore processes within the extension; Swift compilation, signing, shared-session refresh, live network completion, result saving, and cancellation still require macOS/Xcode plus signed physical-device acceptance.
