plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val dartTargetPlatforms = (project.findProperty("target-platform") as? String)
    ?.split(",") ?: listOf("android-arm64", "android-x64")
val dartTargetAbis = dartTargetPlatforms.mapNotNull {
    when (it) {
        "android-arm64" -> "arm64-v8a"
        "android-x64" -> "x86_64"
        else -> null
    }
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
    }

    sourceSets.getByName("main") {
        jniLibs.srcDir("../../native/build/android/jniLibs")
        assets.srcDir("../../native/build/android/assets")
    }

    androidResources {
        val unusedSdkAssets = listOf("arm64-v8a", "x86_64")
            .filterNot { it in dartTargetAbis }
            .flatMap { listOf("dart-sdk-$it.json", "dart-sdk-$it.zip") }
        ignoreAssetsPattern = (listOfNotNull(ignoreAssetsPattern) + unusedSdkAssets)
            .joinToString(":")
    }

    packaging {
        jniLibs.useLegacyPackaging = true
        jniLibs.keepDebugSymbols += "**/libqfli_dart*.so"
    }

    buildTypes {
        configureEach {
            if (project.findProperty("split-per-abi") != "true") {
                // Replace Flutter's build-type defaults as well as SDK ABIs.
                ndk.abiFilters.clear()
                ndk.abiFilters += dartTargetAbis
            }
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

val checkAndroidDartSdk by tasks.registering {
    doLast {
        check(dartTargetPlatforms.all { it == "android-arm64" || it == "android-x64" }) {
            "Android Dart SDK supports only android-arm64 and android-x64"
        }
        check(dartTargetAbis.isNotEmpty()) { "Android Dart SDK requires arm64-v8a or x86_64" }
        for (abi in dartTargetAbis) {
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
