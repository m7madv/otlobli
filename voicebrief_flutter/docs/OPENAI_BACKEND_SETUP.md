# OpenAI backend setup

## Implemented

Only `supabase/functions/process-audio/index.ts` calls OpenAI. The Flutter client has no OpenAI dependency, model name, endpoint, or key.

Default server configuration:

```text
OPENAI_TRANSCRIPTION_MODEL=gpt-4o-mini-transcribe
OPENAI_SUMMARY_MODEL=gpt-5.6-luna
```

This pairing deliberately favors speed and quality per dollar: OpenAI documents
`gpt-4o-mini-transcribe` at an estimated `$0.003`
per audio minute, while `gpt-5.6-luna` is the cost-sensitive GPT-5.6 tier at
`$0.20` input and `$1.20` output per million text tokens as checked on
2026-08-24. Recheck the official model pages before release because pricing
and availability can change.

The function accepts the current audio formats enforced in mobile/server/Storage, sends transcription multipart data, then uses the Responses API with strict JSON Schema. It retries only 429/5xx responses with bounded exponential delay, uses a 90-second attempt timeout, validates output, avoids content logs, and deletes audio in `finally`.

The mobile request supplies a validated Arabic/English system-language hint. The transcription prompt preserves spoken number/date wording. Privacy-safe timing logs record only a short job hash, model, and stage durations. Explicit Arabic day/month phrases are normalized deterministically after structured generation.

## Production deployment — 2026-08-30

`process-audio` is deployed only to project `jyehqpdbayslhzebdycj` as active version `9` with bundle SHA-256 `57b8304000994aec12f851eaaec8b4cf4359e739cc7ef09dd6b876f61dc7bdae`. The production `OPENAI_TRANSCRIPTION_MODEL` secret is `gpt-4o-mini-transcribe`; all unrelated secrets were preserved.

The summary request keeps `gpt-5.6-luna` and strict JSON Schema, but explicitly uses `reasoning.effort=low` and `text.verbosity=low`. On the same representative Arabic smoke sample, this reduced function processing from `19,717ms` to `11,282ms` while preserving the two required dates and confirmation flags. The final safe stage timings were download `1,330ms`, transcription `1,460ms`, summary `7,177ms`, total `11,282ms`; client-observed latency was `14,431ms`.

## Live status — 2026-08-24

- A dedicated service-account key named `VoiceBrief Supabase Production` is active in OpenAI's `Default project` and stored only as the `OPENAI_API_KEY` Supabase Edge secret. It was not written to Flutter, the repository, terminal output, or a local environment file; the transfer clipboard was cleared.
- The prepaid API credit balance still displays `$10.00` after the rounded dashboard refresh, automatic recharge remains `OFF`, and OpenAI states requests stop when credit reaches zero.
- A 14-second synthetic spoken test passed the complete live path with `gpt-transcribe` and `gpt-5.6-luna`: 170 transcript characters, 162 summary characters, two action items, one important date, and at least one resolved ISO date using `UTC+3` context.
- The temporary Auth account and both local/remote test audio were deleted. The service ledger records one used rounded audio minute and zero reserved minutes for `2026-08`.

## Rotation/owner work

```bash
supabase secrets set OPENAI_API_KEY=... \
  OPENAI_TRANSCRIPTION_MODEL=gpt-4o-mini-transcribe \
  OPENAI_SUMMARY_MODEL=gpt-5.6-luna
```

For the initial `$10` prepaid launch balance:

1. Keep OpenAI automatic recharge disabled unless the owner deliberately changes the funding policy.
2. Move from `Default project` to a dedicated OpenAI project when project-level separation is desired; the current key itself is a dedicated VoiceBrief service account.
3. Keep the database `service_budget_months.max_audio_minutes` at the seeded
   `500` minutes per UTC month until real usage and quality are measured. This
   is intentionally conservative and leaves room for model output and bounded
   retries; it is not a dollar-denominated guarantee.
4. Raise the current month only through an owner/server SQL session after the
   funding decision:

```sql
update public.service_budget_months
set max_audio_minutes = 1000, updated_at = now()
where period_key = to_char(timezone('UTC', now()), 'YYYY-MM');
```

Restrict who can rotate the key, and use separate projects for development and
production. Never put this key in `.env` consumed by Flutter or in CI logs.

## Verification

The earlier English smoke and the 2026-08-30 Arabic smoke are complete. The Arabic test used a `24.096s` synthetic sample, preserved the tomorrow and day/month markers, produced separate `2026-08-31` and `2026-09-05` calendar dates, and required confirmation for both ambiguous-time/date-only cases. Its temporary Auth user, Storage object, and test entitlement event were deleted. Before store release, add mixed-language, failure-refund, replay/idempotency, and oversize/hostile-upload acceptance. Ordinary automated tests intentionally use fakes and spend no API credit.

Recheck official model availability, pricing, supported formats, and limits before each release; defaults are configurable precisely so a server rollout need not require a mobile update.
