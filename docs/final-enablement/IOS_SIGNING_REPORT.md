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

The unsigned GitHub candidate is compile evidence only. It cannot be installed
as the requested production/internal signed release and is not App Store-ready.

