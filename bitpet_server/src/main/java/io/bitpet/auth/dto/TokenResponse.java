package io.bitpet.auth.dto;

/**
 * @param linkedProvider 소셜 로그인으로 <b>기존 계정에 방금 새로 연결된</b> 제공자
 *                       (KAKAO / NAVER / GOOGLE). 그 외엔 null — 앱이 연결 안내 토스트에만 쓴다.
 */
public record TokenResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        String linkedProvider
) {
    public static TokenResponse bearer(String access, String refresh) {
        return new TokenResponse(access, refresh, "Bearer", null);
    }

    public TokenResponse withLinkedProvider(String provider) {
        return new TokenResponse(accessToken, refreshToken, tokenType, provider);
    }
}
