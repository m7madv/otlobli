# Secret rotation

## OpenAI

Create a replacement project key, set `OPENAI_API_KEY` in Supabase secrets, deploy/verify a harmless request, then revoke the old key. Review usage for the overlap window.

## Supabase

Use the current platform-recommended publishable/secret key rotation. Update the public mobile key through the build secrets system and service-role secret only in Edge Functions. Rebuild clients when the public key changes. Never paste a service-role key into Flutter.

## RevenueCat webhook

Generate a high-entropy random value. During coordinated rotation, update the Supabase secret and RevenueCat Authorization header together, send a test webhook, then remove the old value. Public SDK keys can be replaced through private Dart defines and a mobile release.

## Apple/Google/signing

- Rotate Apple `.p8`/client secrets in the provider dashboard and keep keys outside Git; update Supabase without changing public Service ID unless necessary.
- Rotate Google client secrets in Supabase/server dashboards; public client IDs normally remain stable.
- Rotate Android upload keys/App Store certificates according to store recovery procedures. Do not commit keystores, `key.properties`, provisioning profiles, or certificates.

## Incident procedure

Revoke first if active compromise is credible, rotate, inspect access/usage/webhook logs without exposing user content, invalidate affected sessions if warranted, document scope/times, and notify users/regulators only under approved legal policy. Secret scanning must pass before every release.
