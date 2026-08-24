plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val damanakKeystorePath = System.getenv("DAMANAK_KEYSTORE_PATH")
val damanakKeystorePassword = System.getenv("DAMANAK_KEYSTORE_PASSWORD")
val damanakKeyAlias = System.getenv("DAMANAK_KEY_ALIAS") ?: "damanak-upload"
val hasDamanakReleaseSigning = !damanakKeystorePath.isNullOrBlank() &&
    !damanakKeystorePassword.isNullOrBlank()

android {
    namespace = "com.damanak.damanak"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.damanak.damanak"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasDamanakReleaseSigning) {
            create("damanakRelease") {
                storeFile = file(damanakKeystorePath!!)
                storePassword = damanakKeystorePassword
                keyAlias = damanakKeyAlias
                keyPassword = damanakKeystorePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasDamanakReleaseSigning) {
                signingConfigs.getByName("damanakRelease")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
