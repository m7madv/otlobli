plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val voicebriefKeystorePath = System.getenv("VOICEBRIEF_KEYSTORE_PATH")
val voicebriefKeystorePassword = System.getenv("VOICEBRIEF_KEYSTORE_PASSWORD")
val voicebriefKeyAlias = System.getenv("VOICEBRIEF_KEY_ALIAS") ?: "voicebrief-upload"
val hasVoicebriefReleaseSigning = !voicebriefKeystorePath.isNullOrBlank() &&
    !voicebriefKeystorePassword.isNullOrBlank()
val isVoicebriefReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (isVoicebriefReleaseBuild && !hasVoicebriefReleaseSigning) {
    throw GradleException(
        "VoiceBrief release signing is required. Set VOICEBRIEF_KEYSTORE_PATH " +
            "and VOICEBRIEF_KEYSTORE_PASSWORD.",
    )
}

android {
    namespace = "app.voicebrief.mobile"
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
        applicationId = "app.voicebrief.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        if (hasVoicebriefReleaseSigning) {
            create("voicebriefRelease") {
                storeFile = file(voicebriefKeystorePath!!)
                storePassword = voicebriefKeystorePassword
                keyAlias = voicebriefKeyAlias
                keyPassword = voicebriefKeystorePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasVoicebriefReleaseSigning) {
                signingConfigs.getByName("voicebriefRelease")
            } else {
                // Non-release IDE sync only. Release tasks fail closed above.
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    implementation("androidx.media3:media3-common:1.11.0")
    implementation("androidx.media3:media3-effect:1.11.0")
    implementation("androidx.media3:media3-transformer:1.11.0")
    androidTestImplementation("androidx.test:runner:1.2.0")
}

flutter {
    source = "../.."
}
