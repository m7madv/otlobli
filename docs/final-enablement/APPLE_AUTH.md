# Sign in with Apple — v86.208

The iOS target declares `com.apple.developer.applesignin=Default`. The native
flow requests name/email and supplies a random 256-bit raw nonce whose SHA-256
hash is sent to Apple. The backend uses Apple JWKS, issuer
`https://appleid.apple.com`, exact configured audience, expiration and nonce
verification; it supports Hide My Email, unique identity linking, authorization
code exchange, refresh-token custody, and revocation during deletion.

The client/provider code and Edge Function are deployed. The safe smoke test
returned `503 apple_auth_not_configured`, correctly proving the live function
does not pretend to work without credentials. Missing Supabase secrets are
`APPLE_SIGN_IN_KEY`, `APPLE_SIGN_IN_KEY_ID`, `APPLE_TEAM_ID`,
`APPLE_CLIENT_ID=com.otlobli.app`, and optionally explicit
`APPLE_CLIENT_IDS=com.otlobli.app`. The Apple App ID capability and regenerated
profile also require portal confirmation. No physical Apple login, Hide My
Email, cancel, restore, logout, linking, or revocation test has run.

