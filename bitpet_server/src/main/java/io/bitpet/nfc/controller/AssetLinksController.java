package io.bitpet.nfc.controller;

import io.bitpet.common.config.DeeplinkProperties;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * Android App Links 검증 파일.
 *
 * <p>{@code https://{host}/.well-known/assetlinks.json} 을 OS 가 직접 가져가 서명 지문을 대조한다.
 * 이 파일이 유효해야 태그 스캔이 브라우저를 거치지 않고 앱으로 바로 들어간다.
 *
 * <p>Nginx 를 앞단에 둘 경우 이 경로를 서버로 프록시하거나 정적 파일로 대체해도 된다.
 * 정적 파일로 둘 때도 {@code Content-Type: application/json} 은 반드시 맞춰야 한다.
 */
@Tag(name = "Deep Link", description = "앱 딥링크 검증·랜딩")
@RestController
@RequiredArgsConstructor
public class AssetLinksController {

    private final DeeplinkProperties deeplinkProperties;

    @Operation(summary = "Android App Links 검증 파일 (서명 지문 미설정 시 404)")
    @GetMapping(value = "/.well-known/assetlinks.json", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<Map<String, Object>>> assetLinks() {
        if (!deeplinkProperties.isConfigured()) {
            // 지문 없는 파일을 내보내면 autoVerify 가 조용히 실패한다 → 아예 없는 편이 낫다
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(List.of(Map.of(
                "relation", List.of("delegate_permission/common.handle_all_urls"),
                "target", Map.of(
                        "namespace", "android_app",
                        "package_name", deeplinkProperties.androidPackageName(),
                        "sha256_cert_fingerprints", deeplinkProperties.sha256CertFingerprints()
                )
        )));
    }
}
