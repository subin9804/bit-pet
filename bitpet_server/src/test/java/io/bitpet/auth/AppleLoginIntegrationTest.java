package io.bitpet.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.bitpet.auth.apple.AppleIdTokenVerifier;
import io.bitpet.auth.domain.OAuthProvider;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.auth.repository.UserOAuthRlsRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.ResultActions;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Apple 로그인 — 신원 토큰 검증(서명·aud·nonce)은 Apple 공개키가 필요해 여기선 대역으로 두고,
 * 검증을 통과한 뒤 계정을 찾고 만드는 규칙을 본다.
 */
class AppleLoginIntegrationTest extends IntegrationTestBase {

    private static final String NONCE = "nonce-0123456789abcdef";

    @Autowired private ObjectMapper objectMapper;
    @Autowired private UserMstRepository userRepository;
    @Autowired private UserOAuthRlsRepository oauthRepository;

    @MockitoBean private AppleIdTokenVerifier verifier;

    @Test
    void first_login_creates_account_with_name_and_relogin_returns_same_account() throws Exception {
        givenToken("tok-new", Map.of("sub", "apple-sub-new",
                "email", "abc123@privaterelay.appleid.com", "email_verified", "true"));

        appleLogin("tok-new", "수빈", "김")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").exists())
                .andExpect(jsonPath("$.data.linkedProvider").doesNotExist());

        var user = userRepository.findByEmail("abc123@privaterelay.appleid.com").orElseThrow();
        assertThat(user.getName()).isEqualTo("김수빈");

        // 두 번째부터 Apple 은 이름을 주지 않는다 — 같은 계정으로 들어와야 한다
        appleLogin("tok-new", null, null).andExpect(status().isOk());
        assertThat(oauthRepository.findByProviderAndProviderUserId(OAuthProvider.APPLE, "apple-sub-new"))
                .get().extracting(l -> l.getUser().getId()).isEqualTo(user.getId());
    }

    @Test
    void verified_email_links_to_existing_account() throws Exception {
        signup("apple-link@example.com", "AppleLink");
        givenToken("tok-link", Map.of("sub", "apple-sub-link",
                "email", "apple-link@example.com", "email_verified", true));

        appleLogin("tok-link", null, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.linkedProvider").value("APPLE"));
    }

    @Test
    void unverified_email_does_not_take_over_existing_account() throws Exception {
        signup("apple-victim@example.com", "AppleVictim");
        givenToken("tok-unverified", Map.of("sub", "apple-sub-unverified",
                "email", "apple-victim@example.com", "email_verified", "false"));

        appleLogin("tok-unverified", null, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.linkedProvider").doesNotExist());

        assertThat(userRepository.findByEmail("apple_apple-sub-unverified@oauth.bitpet.local")).isPresent();
    }

    @Test
    void rejected_token_is_401() throws Exception {
        given(verifier.verify(eq("tok-bad"), anyString()))
                .willThrow(new BusinessException(ErrorCode.AUTH_INVALID_TOKEN));

        appleLogin("tok-bad", null, null).andExpect(status().isUnauthorized());
    }

    @Test
    void withdrawal_unlinks_apple_so_next_login_is_a_new_account() throws Exception {
        givenToken("tok-bye", Map.of("sub", "apple-sub-bye",
                "email", "bye@privaterelay.appleid.com", "email_verified", "true"));
        String access = objectMapper.readTree(appleLogin("tok-bye", null, null)
                .andReturn().getResponse().getContentAsString()).at("/data/accessToken").asText();

        mockMvc.perform(delete("/api/v1/auth/withdraw").header("Authorization", "Bearer " + access))
                .andExpect(status().isOk());

        assertThat(oauthRepository.findByProviderAndProviderUserId(OAuthProvider.APPLE, "apple-sub-bye")).isEmpty();
    }

    private void givenToken(String token, Map<String, Object> claims) {
        Map<String, Object> all = new HashMap<>(claims);
        all.put("iss", "https://appleid.apple.com");
        Jwt jwt = Jwt.withTokenValue(token).header("alg", "RS256").claims(c -> c.putAll(all))
                .issuedAt(Instant.now()).expiresAt(Instant.now().plusSeconds(600)).build();
        given(verifier.verify(eq(token), eq(NONCE))).willReturn(jwt);
    }

    private ResultActions appleLogin(String token, String givenName, String familyName) throws Exception {
        Map<String, Object> body = new HashMap<>();
        body.put("identityToken", token);
        body.put("nonce", NONCE);
        body.put("givenName", givenName);
        body.put("familyName", familyName);
        return mockMvc.perform(post("/api/v1/auth/oauth/apple")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)));
    }

    private void signup(String email, String nickname) throws Exception {
        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", email, "password", "Passw0rd!23", "nickname", nickname,
                                "agreeTos", true, "agreePrivacy", true, "agreeAge", true))))
                .andExpect(status().isCreated());
    }
}
