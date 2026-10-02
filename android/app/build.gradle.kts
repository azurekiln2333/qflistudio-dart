plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.azurekiln.qfli.dartwing"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = providers.gradleProperty("qfliDartNdkVersion")
        .orElse(flutter.ndkVersion).get()

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.azurekiln.qfli.dartwing"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    sourceSets.getByName("main") {
        jniLibs.srcDir("../../native/build/android/jniLibs")
        assets.srcDir("../../native/build/android/assets")
    }

    packaging {
        jniLibs.useLegacyPackaging = true
        jniLibs.keepDebugSymbols += "**/libqfli_dart*.so"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

val checkAndroidDartSdk by tasks.registering {
    val requested = (project.findProperty("target-platform") as? String)
        ?.split(",") ?: listOf("android-arm64", "android-x64")
    val abis = requested.mapNotNull {
        when (it) {
            "android-arm64" -> "arm64-v8a"
            "android-x64" -> "x86_64"
            else -> null
        }
    }
    doLast {
        check(requested.all { it == "android-arm64" || it == "android-x64" }) {
            "Android Dart SDK supports only android-arm64 and android-x64"
        }
        check(abis.isNotEmpty()) { "Android Dart SDK requires arm64-v8a or x86_64" }
        for (abi in abis) {
            val base = rootProject.file("../native/build/android")
            check(file("$base/jniLibs/$abi/libqfli_dartvm.so").isFile &&
                file("$base/assets/dart-sdk-$abi.json").isFile &&
                file("$base/assets/dart-sdk-$abi.zip").isFile) {
                "Stage the complete Android Dart SDK for $abi with native/dart-sdk/android/stage.ps1"
            }
        }
    }
}
tasks.named("preBuild").configure { dependsOn(checkAndroidDartSdk) }

flutter {
    source = "../.."
}
