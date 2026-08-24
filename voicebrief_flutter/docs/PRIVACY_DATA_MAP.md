# Privacy data map

This is an engineering inventory, not a legal promise or final policy.

| Data | Location | Purpose | Retention/deletion |
|---|---|---|---|
| Email, provider user ID, auth tokens | Supabase Auth / protected SDK storage | account access/session | until account deletion or provider/session revocation |
| Supabase user UUID | database, RevenueCat App User ID | ownership, entitlement, quota | until account deletion; RevenueCat retention follows owner agreement |
| Original/imported/recorded audio | app-private temp, App Group handoff, private Supabase Storage | user-requested processing | local copy deleted after processing/failure; remote object deleted in function `finally`; App Group copy consumed/cleaned |
| Transcript and generated brief | Edge Function memory; temporary idempotency job JSON | requested result and safe retry | processing job expires after 24 hours; no analytics/content logging |
| Saved result text | account-scoped Drift database on device | user-selected local history | until user deletes result/history/account or app data |
| Duration and billed minutes | Supabase usage tables | quota enforcement/audit | account lifetime or operational retention policy |
| Product, entitlement, expiry, webhook event ID | RevenueCat/Supabase | subscription access and replay protection | operational/account retention policy |
| Redacted error code and hashed job/user identifier | server diagnostic logs | reliability/security investigation | provider-configured short operational retention |
| Support email, category, subject, message, language, and salted network hash | private Supabase table | respond to support requests and rate-limit abuse | until the request is resolved and no longer operationally required |

## Data flow

Audio enters only after an explicit share/import/record action. The device validates and copies it privately, uploads to the authenticated user/job path, and the Edge Function sends the audio to OpenAI for transcription. Generated text returns to the device; only explicit Save writes it to Drift. No transcript, summary, reply, filename, email, token, or content URI enters ordinary logs.

## Apple App Privacy preparation

Confirm declarations for account identifiers/contact info, user content/audio, purchases, and diagnostics based on final provider contracts and actual telemetry. State processing purpose and whether each third party links data to identity. No advertising/tracking SDK is included.

## Google Play Data Safety preparation

Declare account information, audio/user content, purchase/subscription information, and diagnostics according to final behavior; disclose encryption in transit, deletion request path, temporary processing, and third-party processors. Reconcile declarations with Supabase/OpenAI/RevenueCat terms before submission.

## Owner policy decisions

Define exact database/log/support retention, data processor regions, legal basis/consent, child eligibility, export handling, incident notice, and processor list. The current bilingual public drafts are live at `https://voicebrief-legal.vercel.app` and still require owner/legal approval before store submission.
