# Engineering decisions

## ADR-001 — Direct native sharing

Kotlin `ACTION_SEND` and an actual Swift Share Extension were selected instead of a Flutter share-receive package because reliable content-URI handling, App Group transfer, cold/warm launch, size limits, and duplicate control require platform ownership.

## ADR-002 — Drift without legacy SQLite Flutter bundles

Drift uses current native assets. Direct `drift_flutter`/legacy SQLite bundle dependencies were removed because their resolved transitive native packages were end-of-life.

## ADR-003 — Explicit saves and account-scoped local rows

MVP results are local-only and saved only on explicit action. Rows carry the Supabase user ID so logout/login never crosses account boundaries. Audio is excluded.

## ADR-004 — Server authority for usage and subscription

RevenueCat UI state improves responsiveness, but only webhook-maintained server state and atomic SQL functions grant Pro quota. Local flags cannot grant entitlement or increase minutes.

## ADR-005 — Current OpenAI server defaults

`gpt-transcribe` is the server transcription default for multilingual speech. `gpt-5.6-luna` is the cost-sensitive structured-output default. Both are environment-configurable, and the client knows neither the model nor the OpenAI key.

## ADR-006 — No FFmpeg in MVP

Supported OpenAI formats are accepted directly. An FFmpeg binary was not added because it increases binary size and licensing/maintenance risk without being necessary for the accepted formats.

## ADR-007 — Working identity

The clear placeholder `app.voicebrief.mobile` replaces `com.yourcompany.voicebrief` across Android, iOS, extension, and App Group (`group.app.voicebrief.mobile`). It must be replaced consistently before store registration.

## ADR-008 — Conservative prepaid AI launch budget

The initial OpenAI balance is limited to `$10` with automatic recharge disabled. `gpt-transcribe` remains the high-accuracy transcription default and `gpt-5.6-luna` remains the cost-sensitive structured-output default. A private, server-only database ledger caps the initial service at 500 rounded audio minutes per UTC month; failed work counts against that cap once an AI request starts. This is a conservative operational guard, not a promise that token pricing can never change.

## ADR-009 — Do not send private voice transcripts to Gemini's free tier

Gemini 3.7 Flash is capable and has a free API tier, but Google's Gemini API terms say unpaid-service content and responses may be used to provide, improve, and develop Google products and machine-learning technologies. VoiceBrief therefore keeps transcription and structured summarization on the server-side OpenAI path. Gemini may be reconsidered only with explicit user consent or a paid data-handling tier. Sources: `https://ai.google.dev/gemini-api/docs/models/gemini-3.7-flash`, `https://ai.google.dev/gemini-api/docs/pricing`, and `https://ai.google.dev/gemini-api/terms`.

## ADR-010 — Calendar integration requires review

Relative phrases are resolved using the user's UTC offset, but generated dates are never silently written to the calendar. VoiceBrief shows the interpreted date/time, asks for confirmation, and opens the native Android/iOS event editor so the user remains the final authority over ambiguous speech and system-calendar changes.
