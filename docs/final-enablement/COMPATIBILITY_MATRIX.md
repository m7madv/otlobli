# Compatibility and physical-device matrix — v86.208

| Target | Required coverage | Result |
| --- | --- | --- |
| iPhone 16 Pro Max (`iPhone17,2`), updated iOS 27 beta | complete 30/10/10 SHEIN matrix, policy, region, capture, Temu, push, Google, Apple, deletion, timings | not run — device not connected; signed build unavailable |
| iOS 15 older iPhone | 5 reopens, 5 products, capture/policy/region, push registration, auth availability, memory | not run — device unavailable |
| Samsung Note 8/comparable low-end Android | SHEIN, Temu, capture, policy, live region, Google, FCM states/tap, logout, memory | not run — no ADB device and no signed APK |
| Modern Android/WebView | same functional regression matrix | not run — no ADB device/emulator available |

The owner previously reported about 30 successful store flows after the
affected iPhone received a newer iOS 27 beta/WebKit build. That evidence applies
to the earlier production line, not unbuilt/uninstalled v86.208, and is not
counted as this candidate's acceptance.

