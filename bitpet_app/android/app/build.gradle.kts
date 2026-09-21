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
        // 디버그 서명을 레포 안의 고정 키로 못박는다.
        //
        // 안 그러면 Gradle 이 `~/.android/debug.keystore` 를 쓰는데, 그 파일은
        // 없으면 그 자리에서 새로 만들어진다. CI 러너는 매 실행이 새 VM 이라
        // **빌드할 때마다 서명이 달라지고**, 그러면 앞 빌드 위에 덮어쓸 수 없어
        // (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) 설치할 때마다 앱을 지워야 한다.
        // 지우면 로컬 DB 와 로그인이 날아가니 검증용으로 못 쓴다.
        //
        // 이 키를 레포에 두는 건 안전하다. 디버그 키는 비밀이 아니라 **규격**이다 —
        // 비밀번호가 `android` 로 정해져 있어 누구나 같은 걸 만들 수 있고, 이걸로
        // 서명된 건 Play 가 거부한다. 진짜 릴리즈 키(`key.properties` + .jks)는
        // 예나 지금이나 레포 밖에 있다.
        getByName("debug") {
            val ciDebugKeystore = rootProject.file("ci-debug.keystore")
            if (ciDebugKeystore.exists()) {
                storeFile = ciDebugKeystore
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }

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
