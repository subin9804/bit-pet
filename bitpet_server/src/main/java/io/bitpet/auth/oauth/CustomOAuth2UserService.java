package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.OAuthProvider;
import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.domain.UserOAuthRls;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.auth.repository.UserOAuthRlsRepository;
import io.bitpet.auth.service.NicknamePolicy;
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
                    // 제공자 이름을 그대로 쓰면 안 된다. 닉네임에는 유니크 제약
                    // (idx_user_mst_name_unique)이 걸려 있어서 동명이인이 로그인하는 순간
                    // 제약 위반으로 로그인 자체가 실패한다. 공백·괄호가 섞인 이름도 마찬가지로
                    // 형식 규칙에 어긋나 나중에 프로필 저장이 막힌다.
                    String nickname = NicknamePolicy.makeUnique(
                            NicknamePolicy.sanitizeForOAuth(info.name(), provider.name()),
                            userMstRepository::existsByNameIgnoreCase);
                    UserMst newUser = UserMst.createOAuth(
                            email,
                            nickname,
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
