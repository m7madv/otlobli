# WhatsApp OTP production setup (outbound Baileys)

The active phone-auth implementation is the outbound OTP server in `server/`.
`server-whatsapp/` is a historical copy and must not be deployed. WhatsApp
inbound verification is disabled: there is no supported inbound mode, Meta
webhook, or customer-sends-first flow.

## 1. Customer application environment

Set these values in the iOS and Android build environment:

```text
VITE_WHATSAPP_AUTH_MODE=real
VITE_WHATSAPP_API_URL=https://your-phone-auth-host.example
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=...
```

`VITE_WHATSAPP_API_URL` must be HTTPS and must not end in a private IP or a
localhost address. Production builds fail closed if the mode or URL is missing;
they never fall back to the local mock. `mock` is allowed only in a development
build with `VITE_LOCAL_AUTH_MOCK_ENABLED=true`.

## 2. Phone server environment

Set these only on the host running `server/`:

```text
NODE_ENV=production
PORT=3001
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=...
OTP_HASH_SECRET=<at-least-32-random-bytes>
WHATSAPP_ADMIN_SECRET=<at-least-32-random-bytes>
```

- `SUPABASE_SERVICE_ROLE_KEY` and both secrets are server-only. Never prefix
  them with `VITE_`, place them in Git, or embed them in an IPA/APK.
- `OTP_HASH_SECRET` must contain at least 32 random bytes. It HMACs stored OTPs;
  rotating it intentionally invalidates every outstanding code.
- `WHATSAPP_ADMIN_SECRET` must contain at least 32 random bytes. All session
  upload, reset, status, create, reconnect, delete, and QR-material routes fail
  closed when it is missing or too short. Send it only in the
  `x-whatsapp-admin-secret` request header.
- Keep the Baileys credential directory on persistent encrypted storage. On
  Railway, mount a persistent volume and set `RAILWAY_VOLUME_MOUNT_PATH`; on a
  long-lived host, preserve `server/wa-sessions/`. An ephemeral filesystem
  causes re-pairing after every deployment.

Generate secrets with a cryptographically secure password generator. Do not
reuse the Apple, Supabase, GitHub, database, or admin-panel credential.

## 3. Database contract

Deploy the timestamped Supabase migrations in order through:

```text
supabase/migrations/20260821090000_production_auth_push.sql
supabase/migrations/20260821183000_apple_authorization_client_id.sql
supabase/migrations/20260821193000_harden_identity_rpc_permissions.sql
```

The last migration exposes the service-role-only readiness RPC used by the
phone server. Do not deploy the retired `supabase/migrations_v86_auth_push.sql`
compatibility file.

## 4. Pair or rotate a WhatsApp sender

There is no public browser QR page. QR pixels are generated locally by the
phone server and returned only from authenticated session-management requests;
raw QR text is never returned and QR material is never sent to a third-party QR
service.

Use the existing authenticated admin session panel, or call the API from a
trusted machine:

```text
POST   /api/whatsapp/sessions
GET    /api/whatsapp/sessions
POST   /api/whatsapp/sessions/:id/reconnect
DELETE /api/whatsapp/sessions/:id
```

Every request must include:

```text
x-whatsapp-admin-secret: <WHATSAPP_ADMIN_SECRET>
```

The legacy bulk endpoints `POST /api/session/upload` and
`POST /api/session/reset` are authenticated but deliberately return `410`.
They cannot import an archive or erase every sender. Use the session-specific
create/delete operations above.

To re-pair a sender, delete only that session, create a replacement session,
fetch the protected session list, and scan its locally generated `qrImageUrl`
from WhatsApp **Linked devices**. Confirm the replacement is connected before
removing a healthy fallback sender. Do not delete the persistent credential
directory manually while the server is running.

Rotation rules:

- Rotate `WHATSAPP_ADMIN_SECRET` in the hosting environment and trusted admin
  client together; it does not invalidate a paired WhatsApp sender.
- Rotate `OTP_HASH_SECRET` during a controlled maintenance window because all
  pending OTPs become invalid.
- Re-pair Baileys credentials when a device is logged out, compromised, or
  intentionally replaced. Revoke the old linked device in WhatsApp as well.

## 5. Readiness gate before TestFlight/Android testing

After deploying the migrations and restarting the phone server, request:

```text
GET https://your-phone-auth-host.example/health
```

The release gate requires these exact fields and values:

```json
{
  "status": "ok",
  "whatsappConnected": true,
  "sessionStoreReady": true,
  "authContract": "customer-session-v1",
  "otpSecurityReady": true,
  "whatsappSenderReady": true
}
```

`whatsappSenderReady` is true only while a current Baileys socket is connected;
a stale `creds.json` cannot pass the release gate. The optional
`whatsappCredentialsPresent` field reports only whether persisted credentials
exist and is never a substitute for sender readiness. A green health response
is necessary but not sufficient: send one real six-digit OTP to an iPhone and
one to an Android phone, verify each exactly once, retry an incorrect code, and
confirm resend and rate limits before inviting testers.

## 6. Explicitly unsupported flow

`VITE_WHATSAPP_AUTH_MODE=inbound` is intentionally unavailable and fails closed.
Do not configure a Meta inbound webhook or document a customer-sends-first
workflow as production authentication. The supported flow is:

```text
customer enters phone -> server creates six-digit OTP -> Baileys sends WhatsApp
-> customer enters OTP -> server verifies HMAC-backed challenge -> Supabase
customer session is created
```
