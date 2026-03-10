plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.bigfeatdevelopment.soundscore"
    compileSdk = flutter.compileSdkVersion

    // NDK 25 required for C++17 DSP library
    ndkVersion = "25.1.8937393"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // C++ DSP library (native/CMakeLists.txt at project root)
    externalNativeBuild {
        cmake {
            path = file("../../native/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    defaultConfig {
        applicationId = "com.bigfeatdevelopment.soundscore"
        minSdk = 24           // Android 7.0 — lowest with reliable audio recording
        targetSdk = 34        // Required for new Play Store submissions
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // 64-bit required by Play Store; armeabi-v7a for older devices; x86_64 for emulators
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }

        externalNativeBuild {
            cmake {
                cppFlags += "-std=c++17 -O2"
                arguments += "-DANDROID_STL=c++_shared"
            }
        }
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appName"] = "SoundScore Dev"
            manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            manifestPlaceholders["appName"] = "SoundScore Staging"
            manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
        }
        create("prod") {
            dimension = "environment"
            manifestPlaceholders["appName"] = "SoundScore"
            // Replace with real AdMob App ID before release
            manifestPlaceholders["admobAppId"] = "PLACEHOLDER_ADMOB_ANDROID_APP_ID"
        }
    }

    buildTypes {
        release {
            // TODO: Replace with release signing config before store submission
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            applicationIdSuffix = ".debug"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM — keeps all Firebase library versions in sync
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-crashlytics")
}
