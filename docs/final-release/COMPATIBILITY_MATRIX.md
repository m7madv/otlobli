# Physical compatibility matrix

| Target | Evidence in this release task | Status |
| --- | --- | --- |
| iPhone 16 Pro Max (`iPhone17,2`), newer iOS 27 beta | Owner reports about 30 repeated SHEIN entry/exit/product/cart/navigation/verification flows on the existing app after the OS update without the old freeze. No synchronized log bundle and not v86.207 auth/push acceptance. | SHEIN OS observation passed; v86.207 pending |
| Older iPhone / iOS 15 | Not connected or tested. Minimum target remains iOS 15.0 and availability guards are retained. | Pending |
| Samsung Note 8 / low-memory Android | Not connected in this task. Windows build completed `testDebugUnitTest` and `assembleDebug`; this is not physical acceptance. | Pending physical |
| Modern Android/WebView | Not connected in this task. Production web/Capacitor assets and Android debug compilation pass. | Pending physical |

## Required target-device run

On the iPhone 16 Pro Max run the requested 30 store opens, 10 background
cycles, 10 force-quit cold launches, 30 product navigations, product/root Back,
search/category/verification/capture/cart, store chooser/Temu, Google/Apple,
logout/login/deletion, and APNs foreground/background/terminated delivery.

On old iPhone and both Android classes run store, blocking, region, capture,
authentication, notification receipt/tap, background/termination, and repeated
memory-use flows. Record only tests actually performed; do not infer device
compatibility from compilation.
