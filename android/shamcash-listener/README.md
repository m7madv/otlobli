# Otlobli ShamCash Listener

Dedicated Android notification listener for the merchant ShamCash device.

## Security and delivery model

- Only notifications posted by the fixed package `com.shmacash.shamcash` are considered.
- Incoming-payment classification happens before an event enters the queue and again inside the worker.
- Each notification receives a deterministic SHA-256 `eventId`.
- WorkManager persists one unique job per `eventId`, requires a connected network, and retries transient failures with exponential backoff.
- An unmatched `404` is retried long enough to cover order-creation races, then becomes a failed work item after 12 retries instead of looping forever.
- An event is added to the local deduplication ledger only after a `2xx` server response.
- The shared webhook secret is encrypted with an AES-GCM key generated inside Android Keystore. Version 1 plaintext preferences migrate on first use.
- Every request remains compatible with `x-payment-secret` and also includes replay-resistant migration headers:
  - `x-payment-device`
  - `x-payment-event`
  - `x-payment-timestamp`
  - `x-payment-signature: v1=<hex HMAC-SHA256>`
- The HMAC input is the exact UTF-8 byte sequence:

  ```text
  <deviceId>\n<eventId>\n<timestamp>\n<body bytes>
  ```

The server should verify the signature, timestamp freshness, and `eventId` idempotency before eventually removing the compatibility secret header.

## Protected ADB provisioning

`ConfigReceiver` requires `android.permission.DUMP`. Regular third-party apps cannot call it, while an authorized ADB shell can use an explicit broadcast:

```powershell
adb shell am broadcast `
  -n com.otlobli.shamcashlistener/.ConfigReceiver `
  -a com.otlobli.shamcashlistener.SET_CONFIG `
  --es webhook_url "https://example.invalid/payment-webhook" `
  --es secret "REPLACE_AT_PROVISIONING_TIME"
```

The protected test action is `com.otlobli.shamcashlistener.TEST_NOTIFICATION`. Its text must pass the incoming-payment classifier before it can be queued.

## Release signing

Release builds are non-debuggable and unsigned unless all four values are supplied as Gradle properties or environment variables:

- `OTLOBLI_LISTENER_STORE_FILE`
- `OTLOBLI_LISTENER_STORE_PASSWORD`
- `OTLOBLI_LISTENER_KEY_ALIAS`
- `OTLOBLI_LISTENER_KEY_PASSWORD`

No signing material belongs in this repository. Build from the `android` directory with:

```powershell
.\gradlew.bat :shamcash-listener:testDebugUnitTest :shamcash-listener:assembleRelease
```
