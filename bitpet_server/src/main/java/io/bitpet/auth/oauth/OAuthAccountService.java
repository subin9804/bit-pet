package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.OAuthProvider;
import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.domain.UserOAuthRls;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.auth.repository.UserOAuthRlsRepository;
import io.bitpet.auth.service.NicknamePolicy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * 제공자 계정 → 우리 계정. 브라우저 왕복(카카오·네이버·구글, {@link CustomOAuth2UserService})과
 * 앱 네이티브(Apple, {@code AuthService.loginWithApple}) 두 길이 같은 규칙으로 계정을 찾고 만든다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OAuthAccountService {

    private final UserMstRepository userMstRepository;
    private final UserOAuthRlsRepository userOAuthRlsRepository;
    private final PasswordEncoder passwordEncoder;

    /** @param linkedExisting 이메일이 같은 <b>기존 계정</b>에 이번에 새로 붙었는가 (새 가입이면 false) */
    public record Resolved(UserMst user, boolean linkedExisting) {}

    /**
     * @param encryptedAccessToken  암호화된 제공자 access 토큰 (없으면 null)
     * @param encryptedRefreshToken 암호화된 제공자 refresh 토큰. null 이면 기존 값을 유지한다
     */
    @Transactional
    public Resolved resolve(OAuth2UserInfo info, String encryptedAccessToken, String encryptedRefreshToken) {
        Resolved resolved = userOAuthRlsRepository
                .findByProviderAndProviderUserId(info.provider(), info.providerUserId())
                .filter(this::linkedToActiveUser)
                .map(rls -> {
                    rls.updateTokens(encryptedAccessToken,
                            encryptedRefreshToken != null ? encryptedRefreshToken : rls.getRefreshToken(),
                            rls.getTokenExpiresAt());
                    return new Resolved(rls.getUser(), false);
                })
                .orElseGet(() -> linkOrCreate(info, encryptedAccessToken, encryptedRefreshToken));
        resolved.user().markLoggedIn();
        return resolved;
    }

    /**
     * 탈퇴한 계정에 걸린 연결이면 끊고 새 가입으로 보낸다. 지금은 탈퇴할 때 연결을
     * 지우지만, 그 전에 탈퇴한 계정의 연결은 남아 있다 — 연관 엔티티 로딩에는
     * {@code @SQLRestriction} 이 걸리지 않아서 그대로 두면 탈퇴 계정으로 로그인된다.
     */
    private boolean linkedToActiveUser(UserOAuthRls rls) {
        if (userMstRepository.existsById(rls.getUser().getId())) return true;
        userOAuthRlsRepository.delete(rls);
        userOAuthRlsRepository.flush();
        return false;
    }

    private Resolved linkOrCreate(OAuth2UserInfo info, String encryptedAccessToken, String encryptedRefreshToken) {
        OAuthProvider provider = info.provider();
        // 같은 이메일의 기존 계정에 자동으로 붙이므로, 제공자가 확인한 이메일만 믿는다.
        // 확인 안 된 주소를 받아주면 남의 이메일로 소셜 계정을 만들어 그 사람 계정에
        // 들어갈 수 있다.
        String email = info.email() != null && !info.email().isBlank() && info.emailVerified()
                ? info.email()
                : syntheticEmail(provider, info.providerUserId());

        UserMst existing = userMstRepository.findByEmailLoose(email).orElse(null);
        UserMst user = existing != null ? existing : createUser(info, provider, email);

        UserOAuthRls rls = UserOAuthRls.builder()
                .user(user)
                .provider(provider)
                .providerUserId(info.providerUserId())
                .providerEmail(info.email())
                .accessToken(encryptedAccessToken)
                .refreshToken(encryptedRefreshToken)
                .build();
        userOAuthRlsRepository.save(rls);
        log.info("OAuth linked: provider={}, providerUserId={}, userId={}",
                provider, info.providerUserId(), user.getId());
        return new Resolved(user, existing != null);
    }

    private UserMst createUser(OAuth2UserInfo info, OAuthProvider provider, String email) {
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
    }

    private String syntheticEmail(OAuthProvider provider, String providerUserId) {
        return provider.name().toLowerCase() + "_" + providerUserId + "@oauth.bitpet.local";
    }
}
