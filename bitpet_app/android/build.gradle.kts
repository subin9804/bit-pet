allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

/**
 * 오래된 플러그인의 compileSdk 를 앱과 같은 값으로 끌어올린다.
 *
 * nfc_manager 3.5.1 이 `compileSdkVersion 31` 로 고정되어 있는데, 그게 끌어오는
 * AndroidX 라이브러리 20여 개가 "33 이상으로 컴파일하라"고 요구해서 릴리즈 빌드가
 * 깨진다. (증상은 엉뚱하게 "Install Android SDK Platform 31 failed" 로 나온다)
 *
 * compileSdk 를 올리는 건 **더 새 API 로 컴파일한다**는 뜻일 뿐이고, 런타임 거동은
 * targetSdk, 설치 가능 기기는 minSdk 가 정한다. 그 둘은 건드리지 않으므로 동작은
 * 그대로다 — AGP 가 내는 에러 메시지도 이 구분을 짚어준다.
 *
 * 근본 해결은 nfc_manager 상위 버전으로 올리는 것이지만 4.x 부터 API 가 달라져
 * core/nfc/nfc_reader.dart 를 다시 써야 한다. 그건 별도 작업으로 둔다.
 */
subprojects {
    // :app 은 대상이 아니다. 게다가 위의 evaluationDependsOn(":app") 때문에 이 시점엔
    // 이미 평가가 끝나 있어 afterEvaluate 를 걸면 예외가 난다.
    if (path == ":app") return@subprojects

    fun compileSdkOf(p: Project): Int? =
        p.extensions.findByName("android")?.let { ext ->
            runCatching { ext.javaClass.getMethod("getCompileSdk").invoke(ext) as? Int }.getOrNull()
        }

    fun raiseCompileSdk() {
        val android = extensions.findByName("android") ?: return
        val target = compileSdkOf(project(":app")) ?: return
        val current = compileSdkOf(this) ?: return
        if (current >= target) return

        // AGP 버전마다 DSL 타입이 갈린다(BaseExtension / LibraryExtension / CommonExtension).
        // 타입으로 잡으면 AGP 를 올릴 때 이 스크립트가 깨지므로 setter 만 호출한다.
        runCatching {
            android.javaClass.methods
                .first { it.name == "setCompileSdk" && it.parameterCount == 1 }
                .invoke(android, target)
        }.onSuccess {
            logger.lifecycle("[compileSdk] ${project.name}: $current → $target")
        }
    }

    if (state.executed) raiseCompileSdk() else afterEvaluate { raiseCompileSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
