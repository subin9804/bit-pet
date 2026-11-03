package io.bitpet.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 이메일 대소문자 (2026-11-03). 대소문자만 다른 주소가 다른 계정으로 갈라지면
 * 같은 사람의 소셜 로그인이 기존 계정에 붙지 않고 새 계정을 만든다.
 */
class EmailCaseIntegrationTest extends IntegrationTestBase {

    private static final String PASSWORD = "Passw0rd!23";

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserMstRepository userRepository;

    private void signup(String email, String nickname, int expectedStatus) throws Exception {
        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", email, "password", PASSWORD, "nickname", nickname,
                                "agreeTos", true, "agreePrivacy", true, "agreeAge", true))))
                .andExpect(status().is(expectedStatus));
    }

    @Test
    void mixed_case_signup_is_stored_lowercase_and_logs_in_with_any_case() throws Exception {
        signup("Carol.Case@Example.COM", "CarolCase", 201);

        assertThat(userRepository.findByEmail("carol.case@example.com")).isPresent();

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", "CAROL.case@example.com", "password", PASSWORD))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").exists());
    }

    @Test
    void signup_with_same_address_in_different_case_returns_409() throws Exception {
        signup("dave.case@example.com", "DaveCase", 201);
        signup("Dave.Case@Example.com", "DaveCase2", 409);
    }

    @Test
    void loose_lookup_finds_account_regardless_of_case() throws Exception {
        signup("erin.case@example.com", "ErinCase", 201);

        // 소셜 연결(CustomOAuth2UserService.linkOrCreate)이 쓰는 조회
        assertThat(userRepository.findByEmailLoose("Erin.Case@EXAMPLE.com")).isPresent();
        assertThat(userRepository.findByEmailLoose(null)).isEmpty();
    }
}
