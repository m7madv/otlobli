# WhatsApp inbound verification setup

This project supports the flow where the customer sends a ready WhatsApp message to your business number. The message contains a short code for better matching, but the customer only presses Send in WhatsApp.

## Vercel environment variables

Set these on the customer app project:

```txt
VITE_WHATSAPP_AUTH_MODE=inbound
VITE_SUPPORT_WHATSAPP_PHONE=9639xxxxxxxx
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
OTP_HASH_SECRET=any-long-random-secret
WHATSAPP_WEBHOOK_VERIFY_TOKEN=any-random-token-you-choose
WHATSAPP_APP_SECRET=your-meta-app-secret
```

`WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, and template variables are only needed if the app sends WhatsApp messages itself. The inbound flow does not need them.

## Meta webhook

Use this callback URL:

```txt
https://talabieh.vercel.app/api/webhooks/whatsapp
```

Use the same value from `WHATSAPP_WEBHOOK_VERIFY_TOKEN` as the Meta verify token.

Subscribe the WhatsApp Business Account webhook to:

```txt
messages
```

## Runtime flow

1. Customer enters their WhatsApp number.
2. The app creates a challenge in `otp_challenges`.
3. The app opens `wa.me` with a ready message like `طلبية 1234`.
4. Customer presses Send in WhatsApp.
5. Meta sends the inbound message to `/api/webhooks/whatsapp`.
6. The webhook verifies Meta signature and reads the real sender phone from WhatsApp.
7. If the sender phone and code match the latest pending challenge, it becomes `verified`, and the customer is upserted in `customers` by phone only.
