package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.OAuthProvider;

import java.util.Map;

public interface OAuth2UserInfo {

    OAuthProvider provider();

    String providerUserId();

    String email();

    String name();

    String profileImageUrl();

    Map<String, Object> rawAttributes();
}
