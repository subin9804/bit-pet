package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.OAuthProvider;

import java.util.Map;

public record GoogleOAuth2UserInfo(Map<String, Object> rawAttributes) implements OAuth2UserInfo {

    @Override
    public OAuthProvider provider() {
        return OAuthProvider.GOOGLE;
    }

    @Override
    public String providerUserId() {
        return asString("sub");
    }

    @Override
    public String email() {
        return asString("email");
    }

    @Override
    public String name() {
        String name = asString("name");
        return name != null ? name : asString("given_name");
    }

    @Override
    public String profileImageUrl() {
        return asString("picture");
    }

    private String asString(String key) {
        Object value = rawAttributes.get(key);
        return value != null ? value.toString() : null;
    }
}
