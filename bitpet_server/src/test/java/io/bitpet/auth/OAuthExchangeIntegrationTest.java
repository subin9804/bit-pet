package io.bitpet.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.bitpet.auth.oauth.OAuthLoginCodeStore;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** 소셜 로그인 교환 코드 → 토큰. 제공자 왕복은 여기서 재현하지 않고 코드 발급부터 본다. */
class OAuthExchangeIntegrationTest extends IntegrationTestBase {

    private static final String VERIFIER = "v".repeat(20) + "-verifier_0123456789abcdefghij";

    @Autowired private ObjectMapper objectMapper;
    @Autowired private OAuthLoginCodeStore codeStore;
    @Autowired private UserMstRepository userRepository;

    @Test
    void exchange_with_matching_verifier_issues_tokens_once() throws Exception {
        String code = codeStore.issue(signupUserId("oauth-ok@example.com", "OauthOk"), s256(VERIFIER));

        exchange(code, VERIFIER)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").exists())
                .andExpect(jsonPath("$.data.refreshToken").exists());

        // 같은 코드로 두 번은 안 된다
        exchange(code, VERIFIER).andExpect(status().isUnauthorized());
    }

    @Test
    void exchange_with_wrong_verifier_is_rejected_and_code_is_burned() throws Exception {
        String code = codeStore.issue(signupUserId("oauth-bad@example.com", "OauthBad"), s256(VERIFIER));

        exchange(code, "x".repeat(50)).andExpect(status().isUnauthorized());
        // 틀린 시도 한 번으로 코드는 사라진다 — 맞는 verifier 로도 다시 못 쓴다
        exchange(code, VERIFIER).andExpect(status().isUnauthorized());
    }

    @Test
    void exchange_with_unknown_code_is_rejected() throws Exception {
        exchange("no-such-code", VERIFIER).andExpect(status().isUnauthorized());
    }

    private org.springframework.test.web.servlet.ResultActions exchange(String code, String verifier) throws Exception {
        return mockMvc.perform(post("/api/v1/auth/oauth/exchange")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("code", code, "verifier", verifier))));
    }

    private Long signupUserId(String email, String nickname) throws Exception {
        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", email, "password", "Passw0rd!23", "nickname", nickname,
                                "agreeTos", true, "agreePrivacy", true, "agreeAge", true))))
                .andExpect(status().isCreated());
        return userRepository.findByEmail(email).orElseThrow().getId();
    }

    private static String s256(String verifier) throws Exception {
        byte[] hash = MessageDigest.getInstance("SHA-256").digest(verifier.getBytes(StandardCharsets.US_ASCII));
        return Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
    }
}
