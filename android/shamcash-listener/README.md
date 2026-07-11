# Otlobli ShamCash Listener

Dedicated Android notification listener for the merchant ShamCash device.

## Security and delivery model

- Only notifications posted by the fixed package `com.shmacash.shamcash` are considered.
- Incoming-payment classification happens before an event enters the queue and again inside the worker.
- Each notification receives a deterministic SHA-256 `eventId`.
- WorkManager persists one unique job per `eventId`, requires a connected network, and retries transient failures with exponential backoff.
- Authentication, throttling, and transient server failures are retried with bounded WorkManager backoff. A server `2xx` is terminal, including durable unmatched, rejected, ambiguous, and duplicate results.
- An event is added to the local deduplication ledger only after a `2xx` server response.
- The shared webhook secret is encrypted with an AES-GCM key generated inside Android Keystore. Version 1 plaintext preferences migrate on first use.
- The shared secret is never sent over the network. Every request uses only replay-resistant HMAC headers:
  - `x-payment-device`
  - `x-payment-event`
  - `x-payment-timestamp`
  - `x-payment-signature: v1=<hex HMAC-SHA256>`
- The HMAC input is the exact UTF-8 byte sequence:

  ```text
  <deviceId>\n<eventId>\n<timestamp>\n<body bytes>
  ```

The server verifies the exact-body signature, a five-minute timestamp window, body identity, the fixed ShamCash package, and durable `eventId` idempotency before processing a payment.

## Protected ADB provisioning

`ConfigReceiver` requires `android.permission.DUMP`. Regular third-party apps cannot call it, while an authorized ADB shell can use an explicit broadcast:

```powershell
adb shell am broadcast `
  -n com.otlobli.shamcashlistener/.ConfigReceiver `
  -a com.otlobli.shamcashlistener.SET_CONFIG `
  --es webhook_url "https://example.invalid/payment-webhook" `
  --es secret "REPLACE_AT_PROVISIONING_TIME"
```

Production builds intentionally expose no synthetic-notification action. Tests must use
unit fixtures or a debug-only build; an ADB host must never be able to ask the release app
to sign arbitrary payment-looking text.

## Release signing

Release artifact tasks fail closed unless all four signing values are supplied as Gradle properties or environment variables:

- `OTLOBLI_LISTENER_STORE_FILE`
- `OTLOBLI_LISTENER_STORE_PASSWORD`
- `OTLOBLI_LISTENER_KEY_ALIAS`
- `OTLOBLI_LISTENER_KEY_PASSWORD`

No signing material belongs in this repository. Build from the `android` directory with:

```powershell
.\gradlew.bat :shamcash-listener:testDebugUnitTest :shamcash-listener:assembleRelease
```
