package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.OAuthProvider;

import java.util.Map;

public interface OAuth2UserInfo {

    OAuthProvider provider();

    String providerUserId();

    String email();

    /**
     * 제공자가 이메일 소유를 확인했는지. 네이버는 따로 알려주는 값이 없고 계정
     * 이메일이 본인 확인을 거친 주소라 기본값 true 로 둔다.
     */
    default boolean emailVerified() {
        return true;
    }

    String name();

    String profileImageUrl();

    Map<String, Object> rawAttributes();
}
