package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.OAuthProvider;

import java.util.Map;

public record NaverOAuth2UserInfo(Map<String, Object> rawAttributes) implements OAuth2UserInfo {

    @Override
    public OAuthProvider provider() {
        return OAuthProvider.NAVER;
    }

    @Override
    public String providerUserId() {
        return fromResponse("id");
    }

    @Override
    public String email() {
        return fromResponse("email");
    }

    @Override
    public String name() {
        String name = fromResponse("name");
        return name != null ? name : fromResponse("nickname");
    }

    @Override
    public String profileImageUrl() {
        return fromResponse("profile_image");
    }

    @SuppressWarnings("unchecked")
    private String fromResponse(String key) {
        Object value = rawAttributes.get("response");
        if (!(value instanceof Map)) return null;
        Object item = ((Map<String, Object>) value).get(key);
        return item != null ? item.toString() : null;
    }
}
