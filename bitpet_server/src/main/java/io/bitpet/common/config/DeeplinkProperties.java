package io.bitpet.common.config;

import java.util.List;

/**
 * 앱 딥링크(Android App Links) 설정.
 *
 * <p>{@code sha256-cert-fingerprints} 가 비어 있으면 {@code /.well-known/assetlinks.json} 은 404 를 낸다.
 * 지문이 빠진 assetlinks 를 내보내면 OS 검증이 조용히 실패해 링크가 브라우저로 새므로,
 * 아예 없는 편이 낫다.
 *
 * <p><b>주의</b> — AAB 로 올리면 Google 이 앱을 재서명한다. 진짜로 필요한 것은 업로드 키가 아니라
 * <b>Play 앱 서명 키 지문</b>이고, 이는 앱 업로드 후 Play Console &gt; 설정 &gt; 앱 서명에서 확인한다.
 * 로컬 빌드도 테스트하려면 업로드 키 지문까지 둘 다 넣어둔다.
 */
@org.springframework.boot.context.properties.ConfigurationProperties(prefix = "bitpet.deeplink")
public record DeeplinkProperties(
        String host,
        String androidPackageName,
        List<String> sha256CertFingerprints,
        String playStoreUrl
) {
    public DeeplinkProperties {
        if (host == null || host.isBlank()) host = "bitpet.kr";
        if (androidPackageName == null || androidPackageName.isBlank()) {
            androidPackageName = "io.bitpet.app";
        }
        // 빈 문자열 항목 제거 — 환경변수 미설정 시 [""] 로 들어오는 경우 방어
        sha256CertFingerprints = sha256CertFingerprints == null
                ? List.of()
                : sha256CertFingerprints.stream()
                        .filter(f -> f != null && !f.isBlank())
                        .map(String::trim)
                        .toList();
        if (playStoreUrl == null || playStoreUrl.isBlank()) {
            playStoreUrl = "https://play.google.com/store/apps/details?id=" + androidPackageName;
        }
    }

    public boolean isConfigured() {
        return !sha256CertFingerprints.isEmpty();
    }
}
