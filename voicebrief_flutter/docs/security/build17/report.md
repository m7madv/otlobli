# Security Review: VoiceBriefAuthRepair

## Scope

Standard security scan of voicebrief_flutter at commit 9f228c1 before build 17 remediation.

- Scan mode: scoped_path
- Target kind: git_worktree
- Target ID: target_sha256_d294260cee0c18f27ea5868abf425b0ed1026dc2cc8a0ba6ea94e8b82e497dd0
- Revision: 9f228c14cb6afc21a3301ff1dfb9d69c4752bb7f
- Snapshot digest: codex-security-snapshot/v1:sha256:9c1b03a44ce79330338782ee61ec02e55f200d7ed0f2384938effc9b6a41c768
- Inventory strategy: scoped_path
- Included paths: voicebrief_flutter
- Excluded paths: none
- Runtime or test status: Flutter and Deno tests passed locally; live backend and iPhone runtime pending.
- Artifacts reviewed: Flutter source/tests, iOS Runner/Share Extension, Supabase schema/migrations/Edge Functions, release workflows

Limitations and exclusions:
- Target snapshot is 9f228c1; remediation is in the current working tree.
- Swift and real-device behavior require macOS CI and iPhone acceptance.
- Live Supabase was not modified because the local CLI is authenticated to a different account.

### Scan Summary

| Field | Value |
| --- | --- |
| Scan outcome | completed |
| Reportable findings | 6 |
| Severity mix | high: 1, medium: 5 |
| Confidence mix | high: 6 |
| Coverage | partial |
| Validation mode | Manual source-to-sink validation with focused independent review receipts. |

Canonical artifacts: `scan-manifest.json`, `findings.json`, and `coverage.json`. This report is a deterministic projection of those files.

## Threat Model

VoiceBrief accepts authenticated audio from Flutter and an iOS Share Extension, stores temporary media in Supabase, invokes OpenAI through Edge Functions, and exposes a public support form.

### Assets

- authentication tokens
- private audio
- transcripts and summaries
- quota/service budget
- support availability

### Trust Boundaries

- iOS App Group
- client to Edge Functions
- Storage to process-audio
- public browser to legal function
- Edge Functions to OpenAI

### Attacker Capabilities

- unauthenticated internet requests
- authenticated modified clients
- same-device account switching

### Security Objectives

- account isolation
- server-enforced quota
- bounded uploads/bodies
- retention enforcement
- fail-closed release configuration

## Findings

| Finding | Severity | Confidence | Detailed write-up |
| --- | --- | --- | --- |
| [Client-controlled duration can undercharge quota and service budgets](#finding-1) | high | high | inline below |
| [Concurrent support submissions can bypass the per-window rate limit](#finding-2) | medium | high | inline below |
| [A stale App Group session can attach a processed share result to the wrong local account](#finding-3) | medium | high | inline below |
| [Declared 24-hour expiry is not enforced for job results and abandoned audio](#finding-4) | medium | high | inline below |
| [Authenticated clients can upload arbitrary quantities directly to temporary audio storage](#finding-5) | medium | high | inline below |
| [Chunked support requests can bypass the declared body-size check](#finding-6) | medium | high | inline below |

### Confidence Scale

| Label | Meaning |
| --- | --- |
| high | Direct evidence supports the finding with no material unresolved blocker. |
| medium | Evidence supports a plausible issue, but material runtime or reachability proof remains. |
| low | Evidence is incomplete and the item is retained only for explicit follow-up. |

<a id="finding-1"></a>

### [1] Client-controlled duration can undercharge quota and service budgets

| Field | Value |
| --- | --- |
| Severity | high |
| Confidence | high |
| Confidence rationale | The request value is passed directly to the quota reservation RPC and result. |
| Category | backend |
| CWE | CWE-602, CWE-840 |
| Affected lines | voicebrief_flutter/supabase/functions/process-audio/index.ts:97, voicebrief_flutter/supabase/functions/process-audio/index.ts:311 |

#### Summary

process-audio reserves usage and records results from durationSeconds supplied by the client instead of the uploaded media.

#### Validation

The request value is passed directly to the quota reservation RPC and result. Validation details were not recorded separately.

#### Dataflow

The canonical finding records the affected path at voicebrief_flutter/supabase/functions/process-audio/index.ts:97, voicebrief_flutter/supabase/functions/process-audio/index.ts:311, but no expanded source-to-sink narrative was recorded.

#### Reachability

Reachability was not recorded beyond the canonical finding summary and affected locations.

#### Severity

**High** — Any authenticated modified client can forge a short duration for a long upload and consume paid transcription capacity outside quota.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Derive duration server-side from media metadata, fail closed on invalid media, and reject materially inconsistent client estimates.

<a id="finding-2"></a>

### [2] Concurrent support submissions can bypass the per-window rate limit

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | high |
| Confidence rationale | The check-then-insert sequence has no transaction, lock, or uniqueness guard. |
| Category | support |
| CWE | CWE-362, CWE-799 |
| Affected lines | voicebrief_flutter/supabase/functions/legal/index.ts:450, voicebrief_flutter/supabase/functions/legal/index.ts:469 |

#### Summary

The legal function counts recent requests and inserts separately, so concurrent requests can all observe the same pre-limit count.

#### Validation

The check-then-insert sequence has no transaction, lock, or uniqueness guard. Validation details were not recorded separately.

#### Dataflow

The canonical finding records the affected path at voicebrief_flutter/supabase/functions/legal/index.ts:450, voicebrief_flutter/supabase/functions/legal/index.ts:469, but no expanded source-to-sink narrative was recorded.

#### Reachability

Reachability was not recorded beyond the canonical finding summary and affected locations.

#### Severity

**Medium** — A remote attacker can amplify support-table writes and workload on the public endpoint.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Move count and insertion into one database RPC protected by a transaction-scoped advisory lock keyed to the rate identity.

<a id="finding-3"></a>

### [3] A stale App Group session can attach a processed share result to the wrong local account

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | high |
| Confidence rationale | The scanned Swift flow reuses the shared session and forwards processed results without an account-generation comparison. |
| Category | ios |
| CWE | CWE-613, CWE-639 |
| Affected lines | voicebrief_flutter/ios/ShareExtension/ShareViewController.swift:369, voicebrief_flutter/ios/Runner/AppDelegate.swift:249 |

#### Summary

The Share Extension persists refresh credentials and processed manifests without a session generation that changes on logout or account switch.

#### Validation

The scanned Swift flow reuses the shared session and forwards processed results without an account-generation comparison. Validation details were not recorded separately.

#### Dataflow

The canonical finding records the affected path at voicebrief_flutter/ios/ShareExtension/ShareViewController.swift:369, voicebrief_flutter/ios/Runner/AppDelegate.swift:249, but no expanded source-to-sink narrative was recorded.

#### Reachability

Reachability was not recorded beyond the canonical finding summary and affected locations.

#### Severity

**Medium** — Requires the same unlocked device and a prior share session, but can expose one account's processed result after another account becomes active.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Rotate a session generation on logout/account switch, bind jobs and manifests to user ID plus generation, clear App Group payloads on logout, and reject mismatches.

<a id="finding-4"></a>

### [4] Declared 24-hour expiry is not enforced for job results and abandoned audio

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | high |
| Confidence rationale | The schema stores expiry but its SELECT policy and backend contain no expiry enforcement. |
| Category | retention |
| CWE | CWE-459, CWE-922 |
| Affected lines | voicebrief_flutter/supabase/schema.sql:61, voicebrief_flutter/supabase/schema.sql:129 |

#### Summary

processing_jobs receives expires_at, but the scanned revision does not filter expired rows or purge/redact them; abandoned audio can remain when processing is never invoked.

#### Validation

The schema stores expiry but its SELECT policy and backend contain no expiry enforcement. Validation details were not recorded separately.

#### Dataflow

The canonical finding records the affected path at voicebrief_flutter/supabase/schema.sql:61, voicebrief_flutter/supabase/schema.sql:129, but no expanded source-to-sink narrative was recorded.

#### Reachability

Reachability was not recorded beyond the canonical finding summary and affected locations.

#### Severity

**Medium** — Transcripts or generated results can remain readable past the documented window and sensitive abandoned audio may persist.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Exclude expired jobs from reads, redact expired results on a scheduled server task, and independently remove expired reserved audio.

<a id="finding-5"></a>

### [5] Authenticated clients can upload arbitrary quantities directly to temporary audio storage

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | high |
| Confidence rationale | The INSERT policy constrains folder ownership but not object count, size, MIME, reservation, or rate. |
| Category | storage |
| CWE | CWE-400, CWE-770 |
| Affected lines | voicebrief_flutter/supabase/schema.sql:439 |

#### Summary

The authenticated INSERT policy permits any object under the caller's folder while processing limits run only after upload.

#### Validation

The INSERT policy constrains folder ownership but not object count, size, MIME, reservation, or rate. Validation details were not recorded separately.

#### Dataflow

The canonical finding records the affected path at voicebrief_flutter/supabase/schema.sql:439, but no expanded source-to-sink narrative was recorded.

#### Reachability

Reachability was not recorded beyond the canonical finding summary and affected locations.

#### Severity

**Medium** — An authenticated attacker can create storage cost and retention pressure independently of processing quota.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Remove direct INSERT and issue short-lived signed tokens for an exact reserved path, size, MIME, and job with atomic active and daily limits.

<a id="finding-6"></a>

### [6] Chunked support requests can bypass the declared body-size check

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | high |
| Confidence rationale | The scanned code gates only an optional header before parsing actual bytes. |
| Category | support |
| CWE | CWE-400, CWE-770 |
| Affected lines | voicebrief_flutter/supabase/functions/legal/index.ts:398, voicebrief_flutter/supabase/functions/legal/index.ts:409 |

#### Summary

The public legal function treats absent Content-Length as zero and then buffers formData(), allowing a larger streamed body.

#### Validation

The scanned code gates only an optional header before parsing actual bytes. Validation details were not recorded separately.

#### Dataflow

The canonical finding records the affected path at voicebrief_flutter/supabase/functions/legal/index.ts:398, voicebrief_flutter/supabase/functions/legal/index.ts:409, but no expanded source-to-sink narrative was recorded.

#### Reachability

Reachability was not recorded beyond the canonical finding summary and affected locations.

#### Severity

**Medium** — An unauthenticated remote client can force excessive buffering in an Edge Function invocation.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Read incrementally, cancel and return 413 when actual bytes exceed the limit, and reject unsupported content types before parsing.

## Reviewed Surfaces

| Surface | Risk Area | Outcome | Notes |
| --- | --- | --- | --- |
| Flutter client authentication, preferences, quota, storage and platform bridges | not recorded | Reported | No additional canonical notes were recorded. |
| iOS Runner and Share Extension App Group data flow | not recorded | Reported | No additional canonical notes were recorded. |
| Supabase schema, RLS, storage policies and Edge Functions | not recorded | Reported | No additional canonical notes were recorded. |
| Public legal/support endpoint | not recorded | Reported | No additional canonical notes were recorded. |
| CI and release configuration | not recorded | No issue found | No additional canonical notes were recorded. |
| Independent baseline audit | All scoped security surfaces | Needs follow-up | Six source-backed candidates returned; focused validation is running. |
| Architecture and trust-boundary review | Threat model completeness | No issue found | Architecture map completed and reconciled into focused investigation packets. |
| Production dashboard and exact artifact configuration | Operational assurance | Needs follow-up | Requires external readback and TestFlight artifact verification after source fixes. |

## Open Questions And Follow Up

- Real iPhone account-switch and Share Extension timing acceptance remains.
- Live deployment and scheduled cleanup must be verified only on jyehqpdbayslhzebdycj.
- Awaiting independent focused validation and parent source verification.
  - Follow-up prompt: Review deferred unit ios-app-group-session-generation and close its stated proof gap. Paths: voicebrief_flutter/lib/app/bootstrap.dart, voicebrief_flutter/ios/Runner/AppDelegate.swift, voicebrief_flutter/ios/ShareExtension/ShareViewController.swift, voicebrief_flutter/lib/app/app_controller.dart.
- Awaiting independent focused validation and parent source verification.
  - Follow-up prompt: Review deferred unit unbounded-authenticated-storage and close its stated proof gap. Paths: voicebrief_flutter/supabase/schema.sql, voicebrief_flutter/supabase/functions/delete-account/index.ts.
- Awaiting independent focused validation and parent source verification.
  - Follow-up prompt: Review deferred unit client-asserted-audio-duration and close its stated proof gap. Paths: voicebrief_flutter/supabase/functions/process-audio/index.ts, voicebrief_flutter/supabase/schema.sql.
- Awaiting independent focused validation and parent source verification.
  - Follow-up prompt: Review deferred unit temporary-data-ttl-not-enforced and close its stated proof gap. Paths: voicebrief_flutter/lib/features/transcription/data/transcription_repository.dart, voicebrief_flutter/supabase/functions/process-audio/index.ts, voicebrief_flutter/supabase/schema.sql.
- Awaiting independent focused validation and parent source verification.
  - Follow-up prompt: Review deferred unit support-rate-limit-race and close its stated proof gap. Paths: voicebrief_flutter/supabase/functions/legal/index.ts.
- Awaiting independent focused validation and parent source verification.
  - Follow-up prompt: Review deferred unit public-form-unbounded-body-parse and close its stated proof gap. Paths: voicebrief_flutter/supabase/functions/legal/index.ts.
