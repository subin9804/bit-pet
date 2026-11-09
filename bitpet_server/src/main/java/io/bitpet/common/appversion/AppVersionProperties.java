package io.bitpet.common.appversion;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 앱 강제 업데이트 기준 (2026-11-09).
 *
 * <p>{@code minVersion} 보다 낮은 앱은 아무것도 못 하고 스토어로만 갈 수 있다 — 서버 API 를 깨는 변경을
 * 배포할 때만 올린다. {@code latestVersion} 은 안내용이고 막지 않는다.
 * 배포 후 바로 올리면 스토어 심사·전파가 끝나기 전 사용자가 업데이트할 수 없는 상태로 갇힌다.
 */
@ConfigurationProperties(prefix = "bitpet.app-version")
public record AppVersionProperties(Platform android, Platform ios) {

    public AppVersionProperties {
        if (android == null) android = new Platform(null, null, null);
        if (ios == null) ios = new Platform(null, null, null);
    }

    public record Platform(String minVersion, String latestVersion, String storeUrl) {
        public Platform {
            if (minVersion == null || minVersion.isBlank()) minVersion = "0.0.0";
            if (latestVersion == null || latestVersion.isBlank()) latestVersion = minVersion;
            if (storeUrl == null) storeUrl = "";
        }
    }
}
