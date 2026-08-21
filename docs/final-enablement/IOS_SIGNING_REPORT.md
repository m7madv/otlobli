# iOS signing report — v86.208

## Present in source

- Bundle ID `com.otlobli.app`, version/build `86.208/1070`.
- iPhone/iPad target families and iOS 15 minimum inherited from the accepted
  project.
- Release `aps-environment=production`; Sign in with Apple entitlement.
- Release `WKWebView.isInspectable=false`; PrivacyInfo.xcprivacy included.
- Reproducible GitHub archive/export, entitlement/profile inspection, artifact
  scan, and SHA-256 workflow.

## Missing from secure CI

`APPLE_TEAM_ID`, `IOS_DISTRIBUTION_CERTIFICATE_BASE64`,
`IOS_CERTIFICATE_PASSWORD`, and `IOS_PROVISIONING_PROFILE_BASE64` do not exist
in GitHub Actions secrets. The Apple App ID capability/profile state cannot be
read from this workstation. Consequently no signed archive/IPA was built and
no embedded provisioning or production entitlement was validated.

Unsigned GitHub run `32476867979` passed Xcode from commit
`b679bcad28a0d17c9d33a825af4758dca0c90f1f`. Artifact `9444682658` contains
the inspected 6,557,365-byte IPA with SHA-256
`430A76756C4433719AAADB0EFF03D2E3442D491D24058E1ECDB1201836DB76EF`.
It confirms `com.otlobli.app`, `86.208/1070`, iPhone/iPad `[1,2]`, iOS 15.0,
Privacy Manifest inclusion, no source maps/forbidden markers, and no signature
or embedded profile. It is compile evidence only; it cannot be installed as
the requested production/internal signed release and is not App Store-ready.
