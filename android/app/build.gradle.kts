plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.taprush.app"
    compileSdk = 35

    // Match plugin NDK requirements (path_provider, shared_preferences)
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.taprush.app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildTypes {
        release {
            // While you don’t have a release keystore yet, use debug signing
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

