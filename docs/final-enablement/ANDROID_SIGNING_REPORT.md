# Android signing report — v86.208

Application ID is `com.otlobli.app`, versionName/versionCode are
`86.208/1070`, Release enables R8, resource shrinking, zip alignment, and
disables debugging. Existing Firebase configuration matches the package and
the Android Google/FCM path was not replaced.

Release tasks fail closed unless all four production upload-key inputs exist.
Neither the local secure properties file nor GitHub secrets
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
and `ANDROID_KEY_PASSWORD` are available. No signed AAB/APK was created and no
signature/package verification can therefore be claimed. Play App Signing
portal state is not observable from this environment.

Android Java compilation and unit tests pass; that is not release acceptance.

