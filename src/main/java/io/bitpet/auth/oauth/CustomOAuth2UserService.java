package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.OAuthProvider;
import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.domain.UserOAuthRls;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.auth.repository.UserOAuthRlsRepository;
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
    private final DefaultOAuth2UserService delegate = new DefaultOAuth2UserService();

    @Override
    @Transactional
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User oauth2User = delegate.loadUser(userRequest);
        String registrationId = userRequest.getClientRegistration().getRegistrationId();
        Map<String, Object> attributes = oauth2User.getAttributes();

        OAuth2UserInfo info = OAuth2UserInfoFactory.from(registrationId, attributes);
        if (info.providerUserId() == null) {
            throw new OAuth2AuthenticationException(
                    new OAuth2Error(ErrorCode.AUTH_OAUTH_USER_INFO_MISSING.name(),
                            "providerUserId is missing", null));
        }

        UserMst user = userOAuthRlsRepository
                .findByProviderAndProviderUserId(info.provider(), info.providerUserId())
                .map(rls -> updateOnLogin(rls, info))
                .orElseGet(() -> linkOrCreate(info));

        user.markLoggedIn();
        String nameAttributeKey = userRequest.getClientRegistration()
                .getProviderDetails().getUserInfoEndpoint().getUserNameAttributeName();
        return new OAuth2UserPrincipal(user, attributes, nameAttributeKey);
    }

    private UserMst updateOnLogin(UserOAuthRls rls, OAuth2UserInfo info) {
        // 토큰 정보는 SuccessHandler에서 채울 수도 있으나, 이 단계에서 providerEmail 갱신 정도만.
        return rls.getUser();
    }

    private UserMst linkOrCreate(OAuth2UserInfo info) {
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
