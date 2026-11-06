package io.bitpet.auth.apple;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Apple 로그인 설정.
 *
 * @param clientId 신원 토큰의 aud 로 와야 하는 값 = iOS 번들 ID
 * @param teamId   Apple 개발자 팀 ID (client_secret 서명용)
 * @param keyId    Sign in with Apple 키 ID (client_secret 서명용)
 * @param keyPath  그 키의 .p8 파일 경로. 없으면 로그인은 되고 <b>탈퇴 시 Apple 연결 해제만</b> 건너뛴다
 */
@ConfigurationProperties(prefix = "bitpet.apple")
public record AppleProperties(
        String clientId,
        String teamId,
        String keyId,
        String keyPath
) {}
