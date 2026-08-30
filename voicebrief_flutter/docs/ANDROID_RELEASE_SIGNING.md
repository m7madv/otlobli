# Android release signing

VoiceBrief now fails closed for release builds unless an owned upload key is supplied. Debug builds remain unchanged.

## Private material on this workstation

The signing material is intentionally outside Git:

```text
C:\Users\MOHAMMAD\.voicebrief\android\voicebrief-upload.jks
C:\Users\MOHAMMAD\.voicebrief\android\voicebrief-signing.credential.xml
C:\Users\MOHAMMAD\.voicebrief\android\build-voicebrief-release.ps1
```

The credential file is encrypted with Windows DPAPI for the current Windows account. The directory ACL is restricted to the current account and `SYSTEM`. No password, keystore, private key, or credential file exists under the repository.

Keystore file SHA-256 for backup-integrity checks: `5DB60B69413422FA327264AD118754E642D8806B34C99FC0EE3272ACC371FF21`.

Build both signed artifacts with:

```powershell
& 'C:\Users\MOHAMMAD\.voicebrief\android\build-voicebrief-release.ps1' `
  -ProjectPath 'C:\Users\MOHAMMAD\Projects\VoiceBriefAuthRepair\voicebrief_flutter'
```

The script loads the DPAPI credential, sets signing variables only for the build process, clears them in `finally`, reads the marketing/build numbers from `pubspec.yaml`, and copies clearly named outputs to `output/voicebrief/`.

## Upload certificate

```text
Alias: voicebrief-upload
Subject: CN=VoiceBrief, OU=Mobile, O=VoiceBrief, L=Riyadh, ST=Riyadh, C=SA
Algorithm: RSA 4096 / SHA384withRSA
Valid through: 2054-01-09
SHA-1: 43:89:D6:0A:58:EA:21:08:5E:65:37:27:47:6D:7A:E9:42:42:ED:E7
SHA-256: 81:AA:4D:A6:E4:25:79:4E:88:0C:8D:DE:0A:75:68:F6:8C:EE:77:4A:3C:18:89:17:02:21:AD:04:46:EE:8F:D9
```

Google OAuth debug certificate on this workstation:

```text
SHA-1: 97:1C:7E:FE:3D:10:09:BD:80:0B:8A:EA:2C:A5:9F:64:7C:E1:68:A3
SHA-256: 33:71:5A:67:2B:35:53:4F:DC:DC:64:8E:52:22:39:D8:A9:1F:01:30:39:0C:1A:BD:73:85:68:BF:74:63:A3:E9
```

Google Play App Signing will issue a separate app-signing certificate after the first Play Console setup. Add that Play SHA-1/SHA-256 to Google OAuth as well; do not substitute the upload certificate for it.

## Required backup before first store upload

DPAPI protects the password but is tied to this Windows account. Before the first Play upload, the owner must place the `.jks` file and its password in two separate, recoverable encrypted backups or an approved password manager. Losing both can make future updates difficult even though Play key reset procedures may exist. Never copy the password into source, chat, CI logs, or a plaintext note.
