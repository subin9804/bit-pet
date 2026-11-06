package io.bitpet.auth.apple;

import io.bitpet.auth.domain.OAuthProvider;
import io.bitpet.auth.oauth.OAuth2UserInfo;

import java.util.Map;

/**
 * 검증을 마친 Apple 신원 토큰의 클레임 + 앱이 따로 넘긴 이름.
 *
 * <p>Apple 은 이름을 토큰에 넣지 않고 <b>처음 로그인할 때 한 번만</b> 앱에 준다.
 * 그 뒤로는 null 이라 닉네임은 'APPLE' 기반으로 만들어진다 (재로그인은 기존 계정이라 상관없다).
 */
public record AppleUserInfo(Map<String, Object> rawAttributes, String name) implements OAuth2UserInfo {

    @Override
    public OAuthProvider provider() {
        return OAuthProvider.APPLE;
    }

    @Override
    public String providerUserId() {
        return asString("sub");
    }

    /** 사용자가 '이메일 가리기'를 고르면 {@code ...@privaterelay.appleid.com} 중계 주소가 온다 */
    @Override
    public String email() {
        return asString("email");
    }

    /** 문자열 "true" 로 올 때도 있고 불리언으로 올 때도 있다 */
    @Override
    public boolean emailVerified() {
        return Boolean.parseBoolean(asString("email_verified"));
    }

    @Override
    public String profileImageUrl() {
        return null;
    }

    private String asString(String key) {
        Object value = rawAttributes.get(key);
        return value != null ? value.toString() : null;
    }
}
