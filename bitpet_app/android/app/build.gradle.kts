import java.io.FileInputStream
import java.util.Properties

// 릴리즈 서명 정보는 `android/key.properties` 에서 읽는다 (gitignore, 레포가 public).
// 파일이 없어도 빌드는 되게 둔다 — 없으면 아래에서 디버그 키로 폴백한다.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    // FCM — android/app/google-services.json 을 읽어 Firebase 설정 주입
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "me.tailog.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications 요구사항 (구버전 안드로이드에서 java.time 사용)
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // tailog.me 를 뒤집은 값. Play 업로드 후에는 영구 고정이라 변경 금지.
        // iOS 번들 ID(ios/Runner.xcodeproj)도 같은 값으로 맞춰져 있다.
        applicationId = "me.tailog.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion // flutter_secure_storage + sqlite3_flutter_libs 요구사항
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }

    buildTypes {
        release {
            // key.properties 가 없으면 디버그 키로 폴백한다.
            //
            // 이렇게 두는 이유: 실기기 릴리즈 검증(`flutter run --release`)과 새로 클론한
            // 환경의 빌드가 키스토어 없이도 돌아가야 한다. 키스토어는 레포에 없으니까.
            //
            // ⚠️ 대신 디버그 키로 서명된 AAB 는 Play 가 거부한다. 조용히 넘어가면
            // 업로드 단계에서야 알게 되므로 빌드할 때 크게 경고한다.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "\n" +
                    "⚠️  android/key.properties 가 없어 릴리즈를 **디버그 키**로 서명합니다.\n" +
                    "    실기기 테스트는 이대로 가능하지만, 이 AAB 는 Play 에 올릴 수 없습니다.\n"
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
