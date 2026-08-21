# Push physical test report — v86.208

No compatible physical iPhone or Android device was connected to this Windows
workstation, and signing/provider credentials are unavailable. No delivery
claim is made.

| Test | Result |
| --- | --- |
| iOS permission and APNs registration | not run |
| token reaches production registry | not run |
| iOS foreground/background/terminated delivery | not run |
| iOS tap opens allowlisted internal screen | not run |
| APNs invalid-token cleanup | not run |
| iOS logout/login ownership | not run |
| Android FCM foreground/background/terminated | not run |
| Android notification tap and ownership | not run |

Static and contract tests cover permission gating, payload version and route
allowlist, token upsert/rotation/detach behavior, terminated-launch buffering,
APNs retry/permanent status handling, and Android provider preservation. These
checks are not a substitute for physical delivery.

