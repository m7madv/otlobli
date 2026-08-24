# Configuration

All public mobile values are typed in `AppConfig` and supplied with Dart defines. Start from `dart-defines.example.json`.

| Value | Mobile-safe | Purpose |
|---|---:|---|
| `APP_ENV` | yes | environment label |
| `USE_MOCK_SERVICES` | yes | deterministic demo vs production repositories |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | yes | public Supabase client configuration; RLS remains mandatory |
| RevenueCat public SDK keys | yes | platform SDK initialization; they do not authorize webhook writes |
| Google iOS/web client IDs | yes | OAuth client identity, not a secret |
| Apple Service ID/redirect URI | yes | public OAuth identifiers |

Server-only values in `.env.example` must be set as Edge Function secrets: OpenAI key, service-role key, RevenueCat webhook secret, and any provider private key/secret.

Centralized production candidates in `lib/app/config/app_config.dart`:

```text
Android/iOS: app.voicebrief.mobile
iOS extension: app.voicebrief.mobile.share
App Group: group.app.voicebrief.mobile
Scheme: voicebrief
Google iOS callback scheme: com.googleusercontent.apps.872187920899-72jkr1l4pb84u6umrkhdkidun1iieapd
Products: voicebrief_pro_monthly / voicebrief_pro_annual
Legal/support URLs: https://voicebrief-legal.vercel.app/...
```

Before changing an identity, update Dart constants, Android namespace/application ID/Kotlin package, Xcode Runner/extension bundle IDs, both entitlements, OAuth/store/App Group dashboards, and deep-link allowlists together. Search with:

```bash
rg "app\.voicebrief\.mobile|group\.app\.voicebrief\.mobile|voicebrief-legal\.vercel\.app" .
```

Production run example:

```bash
flutter run --dart-define-from-file=dart-defines.production.json
```

Keep that production file ignored and in an approved secrets system. The local ignored production file now contains the public Google iOS/web client IDs; the Google web client secret exists only in the hosted Supabase Auth configuration.
