# Google Sign-In on iOS — v86.208

The app uses the maintained `@capgo/capacitor-social-login` native integration
and the existing Otlobli customer/session model. The backend verifies Google ID
tokens against configured audiences, issuer, expiration and verified subject;
database uniqueness prevents duplicate provider identities and unsafe linking.
No OAuth client secret is stored in the app.

The iOS action is intentionally hidden until `VITE_GOOGLE_IOS_CLIENT_ID` is
present. CI then writes `GIDClientID` and the derived
`com.googleusercontent.apps.<client-prefix>` callback scheme. The Web/server
client remains
`677396296147-o5q0rt5qk2rq0rqh714kuki7gabkdmcu.apps.googleusercontent.com`.

The exact iOS OAuth client for Bundle ID `com.otlobli.app` is not present in
GitHub secrets. `GOOGLE_CLIENT_IDS` exists in Supabase, but it must retain the
current Web/Android audiences and append the new iOS client. Until both actions
are completed and physical first-login/cancel/restore/logout/account-link tests
pass, Google Sign-In on iOS is not accepted.

