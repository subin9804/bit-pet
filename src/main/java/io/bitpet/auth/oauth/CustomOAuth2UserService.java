package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.OAuthProvider;
import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.domain.UserOAuthRls;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.auth.repository.UserOAuthRlsRepository;
import io.bitpet.auth.service.TokenEncryptor;
import io.bitpet.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class CustomOAuth2UserService implements OAuth2UserService<OAuth2UserRequest, OAuth2User> {

    private final UserMstRepository userMstRepository;
    private final UserOAuthRlsRepository userOAuthRlsRepository;
    private final PasswordEncoder passwordEncoder;
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

        String encryptedAccessToken = tokenEncryptor.encrypt(rawAccessToken);
        UserMst user = userOAuthRlsRepository
                .findByProviderAndProviderUserId(info.provider(), info.providerUserId())
                .map(rls -> updateOnLogin(rls, info, encryptedAccessToken))
                .orElseGet(() -> linkOrCreate(info, encryptedAccessToken));

        user.markLoggedIn();
        String nameAttributeKey = userRequest.getClientRegistration()
                .getProviderDetails().getUserInfoEndpoint().getUserNameAttributeName();
        return new OAuth2UserPrincipal(user, attributes, nameAttributeKey);
    }

    private UserMst updateOnLogin(UserOAuthRls rls, OAuth2UserInfo info, String encryptedAccessToken) {
        rls.updateTokens(encryptedAccessToken, rls.getRefreshToken(), rls.getTokenExpiresAt());
        return rls.getUser();
    }

    private UserMst linkOrCreate(OAuth2UserInfo info, String encryptedAccessToken) {
        OAuthProvider provider = info.provider();
        String email = info.email() != null && !info.email().isBlank()
                ? info.email()
                : syntheticEmail(provider, info.providerUserId());

        UserMst user = userMstRepository.findByEmail(email)
                .orElseGet(() -> {
                    String randomHash = passwordEncoder.encode(UUID.randomUUID().toString());
                    UserMst newUser = UserMst.createOAuth(
                            email,
                            info.name() != null ? info.name() : provider.name() + " User",
                            info.profileImageUrl(),
                            randomHash);
                    return userMstRepository.save(newUser);
                });

        UserOAuthRls rls = UserOAuthRls.builder()
                .user(user)
                .provider(provider)
                .providerUserId(info.providerUserId())
                .providerEmail(info.email())
                .accessToken(encryptedAccessToken)
                .build();
        userOAuthRlsRepository.save(rls);
        log.info("OAuth linked: provider={}, providerUserId={}, userId={}",
                provider, info.providerUserId(), user.getId());
        return user;
    }

    private String syntheticEmail(OAuthProvider provider, String providerUserId) {
        return provider.name().toLowerCase() + "_" + providerUserId + "@oauth.bitpet.local";
    }
}
