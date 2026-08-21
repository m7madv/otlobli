# Push notifications test report

Status: **code-complete, not physically accepted**.

## Passed locally

- TypeScript and Vite production build.
- Versioned payload allowlist unit tests.
- Static checks for protected send endpoint, platform/provider separation,
  token rotation RPC, logout detachment, and invalid-token cleanup.
- Capacitor iOS and Android sync with Push Notifications plugin present.
- Android `testDebugUnitTest` and `assembleDebug`.
- Xcode entitlements/project configuration inspection.
- GitHub/Xcode unsigned build `32441115523`, including production-asset scan
  and universal iPhone/iPad inspection. This cannot validate APNs because the
  artifact is unsigned and has no provisioning profile.

## Not executed

No iPhone was USB-connected during this release task. APNs credentials,
provisioning profiles, and backend production secrets are not configured in the
repository or GitHub, so none of the following has been claimed:

- APNs registration success on the physical iPhone;
- token row observed in the live backend;
- foreground, background, or terminated delivery;
- tap routing on a real notification;
- production/sandbox delivery verification;
- permission-denied Settings flow on device;
- token rotation and logout/login ownership on live data;
- Android FCM delivery regression test on a physical device.

The release gate remains closed until every item above passes and evidence is
recorded here (device, OS, timestamp, token environment, sanitized provider
result, and resulting in-app route; never record the token itself).
