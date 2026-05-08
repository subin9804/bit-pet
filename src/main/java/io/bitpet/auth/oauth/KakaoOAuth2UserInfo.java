package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.OAuthProvider;

import java.util.Map;

public record KakaoOAuth2UserInfo(Map<String, Object> rawAttributes) implements OAuth2UserInfo {

    @Override
    public OAuthProvider provider() {
        return OAuthProvider.KAKAO;
    }

    @Override
    public String providerUserId() {
        Object id = rawAttributes.get("id");
        return id != null ? id.toString() : null;
    }

    @Override
    public String email() {
        Map<String, Object> kakaoAccount = kakaoAccount();
        if (kakaoAccount == null) return null;
        Object email = kakaoAccount.get("email");
        return email != null ? email.toString() : null;
    }

    @Override
    public String name() {
        Map<String, Object> profile = profile();
        if (profile == null) return null;
        Object nickname = profile.get("nickname");
        return nickname != null ? nickname.toString() : null;
    }

    @Override
    public String profileImageUrl() {
        Map<String, Object> profile = profile();
        if (profile == null) return null;
        Object url = profile.get("profile_image_url");
        return url != null ? url.toString() : null;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> kakaoAccount() {
        Object value = rawAttributes.get("kakao_account");
        return value instanceof Map ? (Map<String, Object>) value : null;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> profile() {
        Map<String, Object> account = kakaoAccount();
        if (account == null) return null;
        Object profile = account.get("profile");
        return profile instanceof Map ? (Map<String, Object>) profile : null;
    }
}
