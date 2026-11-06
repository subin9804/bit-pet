package io.bitpet.nfc.controller;

import io.bitpet.auth.apple.AppleProperties;
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
 * iOS 유니버설 링크 검증 파일 — {@link AssetLinksController} 의 iOS 짝.
 *
 * <p>Apple CDN 이 {@code https://{host}/.well-known/apple-app-site-association} 을 가져가
 * 앱의 associated-domains 와 대조한다. 맞으면 태그 URL({@code /t/*})이 사파리 대신 앱으로 열린다.
 *
 * <p>appID 는 {@code 팀ID.번들ID}. 팀 ID 가 없으면 404 — 틀린 appID 를 내보내면 검증이
 * 조용히 실패하고 Apple CDN 이 그 결과를 한동안 캐시한다.
 *
 * <p>⚠️ 경로에 확장자가 없지만 {@code Content-Type: application/json} 이어야 한다. 리다이렉트도 안 된다.
 */
@Tag(name = "Deep Link", description = "앱 딥링크 검증·랜딩")
@RestController
@RequiredArgsConstructor
public class AppleAppSiteAssociationController {

    private final AppleProperties appleProperties;

    @Operation(summary = "iOS 유니버설 링크 검증 파일 (팀 ID 미설정 시 404)")
    @GetMapping(value = "/.well-known/apple-app-site-association", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Map<String, Object>> association() {
        String teamId = appleProperties.teamId();
        if (teamId == null || teamId.isBlank()) {
            return ResponseEntity.notFound().build();
        }
        String appId = teamId + "." + appleProperties.clientId();
        return ResponseEntity.ok(Map.of("applinks", Map.of(
                "details", List.of(Map.of(
                        "appIDs", List.of(appId),
                        // NFC 이름표 URL 만. 홈·약관 페이지까지 앱으로 끌어가지 않는다
                        "components", List.of(Map.of("/", "/t/*"))
                ))
        )));
    }
}
