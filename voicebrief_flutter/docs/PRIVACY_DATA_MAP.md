# Privacy data map

This is an engineering inventory, not a legal promise or final policy.

| Data | Location | Purpose | Retention/deletion |
|---|---|---|---|
| Email, provider user ID, auth tokens, and provider-supplied name/profile image | Supabase Auth / protected SDK storage | account access/session and account display | until account deletion or provider/session revocation; Sign in with Apple access may require separate manual revocation |
| Supabase user UUID | database; RevenueCat App User ID | ownership, entitlement, and quota | Supabase copy until account deletion; RevenueCat deletion/retention is separate and follows the owner agreement and provider policy |
| Original/imported/recorded audio | app-private temp, App Group handoff, private Supabase Storage | user-requested processing | the normal path deletes local copies and attempts remote deletion in `finally`; an interruption can leave a private object until operational cleanup or account deletion. Source includes independent two-pass Storage API cleanup for an abandoned reservation after its two-hour expiry: the first pass starts after a 15-minute safety grace, keeps a tombstone, and a later scheduled pass repeats removal after at least another 15 minutes before retiring that pointer. This cleanup is pending live deployment. App Group copies are consumed/cleaned in the normal handoff path |
| Audio, transcript/prompt, and generated response sent for AI processing | OpenAI API | transcription and requested result generation | requests set `store: false`; OpenAI may retain API inputs/outputs in abuse-monitoring logs for up to 30 days unless the VoiceBrief account is approved and configured for Zero Data Retention or Modified Abuse Monitoring. Zero Data Retention is not currently evidenced |
| Transcript and complete generated brief (summary, key points, tasks, dates, and replies) | Edge Function memory; Supabase `processing_jobs.result` JSON | requested result, safe retry, and duplicate-charge prevention | the processing job and full result expire after 24 hours; no content is intentionally written to ordinary application logs |
| Saved result text | account-scoped Drift database on device | local history and opening completed Share Extension results | ordinary in-app results are written only after explicit Save; imported Share Extension results are written locally automatically so the completion notification can open them; retained until the user deletes the result/history/account or app data |
| Duration and billed minutes | Supabase usage tables | quota enforcement/audit | account lifetime or operational retention policy |
| Product, entitlement, purchase/expiration status, store transaction history, webhook event ID | RevenueCat, Apple/Google store, Supabase | subscription access, purchase restoration, and replay protection | Supabase operational/account retention; store and RevenueCat records may remain under provider policy and legal requirements. Canceling the store subscription is separate from deleting the VoiceBrief account |
| Redacted error code and hashed job/user identifier | server diagnostic logs | reliability/security investigation | provider-configured short operational retention |
| Support/deletion-request email, category, subject/message or note, language, sign-in provider, confirmation, and salted network hash | private Supabase support table (deletion fields are encoded into the account-request message) | respond, verify account ownership, process deletion requests, and rate-limit abuse | no fixed deletion period is currently promised; retained as needed to respond, verify ownership, investigate abuse, protect the service, and satisfy legal obligations |

## Data flow

Audio enters only after an explicit share/import/record action. The device validates and copies it privately, uploads to the authenticated user/job path, and the Edge Function sends the audio to OpenAI for transcription. The transcript is then sent to OpenAI for result generation with `store: false`. The complete result may remain in `processing_jobs.result` for up to 24 hours. In the ordinary in-app flow only explicit Save writes the result to Drift; the Share Extension import path writes its completed result to Drift automatically so a local notification can open it. No transcript, summary, reply, filename, email, token, or content URI is intentionally written to ordinary application logs.

## Apple App Privacy preparation

Prepare declarations for contact information (email and provider-supplied name), account/user identifiers, provider-supplied profile image, audio and generated user content, purchases/subscriptions, and diagnostics. State processing purposes and identity linkage based on the account-scoped flow and final processor contracts. No advertising/tracking SDK is included, and the current code does not use data for cross-company tracking.

## Google Play Data Safety preparation

Declare account information, provider-supplied name/profile image, audio and generated user content, purchase/subscription information, and diagnostics according to final behavior. Disclose encryption in transit, the public `/delete-account` request path, temporary processing, and Supabase/OpenAI/RevenueCat plus Apple/Google as processors or store services. Reconcile declarations with final provider terms before submission.

## Owner policy decisions

Define exact database/log/support-and-deletion-request retention, data processor regions, legal basis/consent, child eligibility, export handling, incident notice, and processor list. Confirm whether the OpenAI organization has Zero Data Retention or Modified Abuse Monitoring, define RevenueCat deletion handling, and decide whether Sign in with Apple revocation will be automated or documented as manual. The bilingual source drafts require owner/legal approval and redeployment before their `2026-08-30` content and `/delete-account` route can be treated as live.
