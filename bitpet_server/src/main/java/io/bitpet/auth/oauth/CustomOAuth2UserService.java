package io.bitpet.auth.oauth;

import io.bitpet.auth.service.TokenEncryptor;
import io.bitpet.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class CustomOAuth2UserService implements OAuth2UserService<OAuth2UserRequest, OAuth2User> {

    private final OAuthAccountService oAuthAccountService;
    private final TokenEncryptor tokenEncryptor;
    private final DefaultOAuth2UserService delegate = new DefaultOAuth2UserService();

    @Override
    @Transactional
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User oauth2User = delegate.loadUser(userRequest);
        String registrationId = userRequest.getClientRegistration().getRegistrationId();
        String rawAccessToken = userRequest.getAccessToken().getTokenValue();
        Map<String, Object> attributes = oauth2User.getAttributes();

        OAuth2UserInfo info = OAuth2UserInfoFactory.from(registrationId, attributes);
        if (info.providerUserId() == null) {
            throw new OAuth2AuthenticationException(
                    new OAuth2Error(ErrorCode.AUTH_OAUTH_USER_INFO_MISSING.name(),
                            "providerUserId is missing", null));
        }

        OAuthAccountService.Resolved resolved =
                oAuthAccountService.resolve(info, tokenEncryptor.encrypt(rawAccessToken), null);

        String nameAttributeKey = userRequest.getClientRegistration()
                .getProviderDetails().getUserInfoEndpoint().getUserNameAttributeName();
        return new OAuth2UserPrincipal(resolved.user(), attributes, nameAttributeKey,
                resolved.linkedExisting() ? info.provider() : null);
    }
}
