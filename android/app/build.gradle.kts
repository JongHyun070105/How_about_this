plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    signingConfigs {
        getByName("debug") {
            storeFile = file("/Users/macintosh/myandroidkey")
            keyAlias = "key"
            storePassword = "brian07!"
            keyPassword = "brian07!"
        }
    }
    namespace = "com.jonghyun.reviewai_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Core library desugaring 활성화
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.jonghyun.reviewai_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 2  // 직접 2로 지정
        versionName = "1.0.1"
        
        // MultiDex 지원 (필요시)
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // signingConfig = signingConfigs.getByName("release") // 서명 설정 제거
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring dependency 추가
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}