package io.bitpet.auth.domain;

public enum OAuthProvider {
    GOOGLE,
    KAKAO,
    NAVER,
    /** 브라우저 왕복이 아니라 앱 네이티브 로그인 → {@code POST /auth/oauth/apple} 로만 들어온다 */
    APPLE
}
