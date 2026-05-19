package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.OAuthProvider;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;

import java.util.Map;

public final class OAuth2UserInfoFactory {

    private OAuth2UserInfoFactory() {
    }

    public static OAuth2UserInfo from(String registrationId, Map<String, Object> attributes) {
        OAuthProvider provider;
        try {
            provider = OAuthProvider.valueOf(registrationId.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.AUTH_OAUTH_PROVIDER_NOT_SUPPORTED,
                    "Unsupported OAuth provider: " + registrationId);
        }
        return switch (provider) {
            case GOOGLE -> new GoogleOAuth2UserInfo(attributes);
            case KAKAO  -> new KakaoOAuth2UserInfo(attributes);
            case NAVER  -> new NaverOAuth2UserInfo(attributes);
        };
    }
}
