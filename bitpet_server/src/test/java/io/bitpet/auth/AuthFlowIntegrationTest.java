package io.bitpet.auth;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AuthFlowIntegrationTest extends IntegrationTestBase {

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void signup_then_login_then_refresh_returns_new_tokens() throws Exception {
        String email = "alice@example.com";
        String password = "Passw0rd!23";

        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", email,
                                "password", password,
                                "nickname", "Alice",
                                // 필수 약관 3종. 빼면 @AssertTrue 가 걸려 400 이다.
                                "agreeTos", true,
                                "agreePrivacy", true,
                                "agreeAge", true))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.email").value(email))
                .andExpect(jsonPath("$.data.userType").value("GENERAL"));

        MvcResult loginResult = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", email,
                                "password", password))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").exists())
                .andExpect(jsonPath("$.data.refreshToken").exists())
                .andReturn();

        JsonNode loginBody = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        String refreshToken = loginBody.path("data").path("refreshToken").asText();
        assertThat(refreshToken).isNotBlank();

        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("refreshToken", refreshToken))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").exists())
                .andExpect(jsonPath("$.data.refreshToken").exists());
    }

    @Test
    void signup_with_duplicate_email_returns_409() throws Exception {
        String email = "bob@example.com";
        String password = "Passw0rd!23";
        Map<String, Object> body = Map.of("email", email, "password", password, "nickname", "Bob",
                "agreeTos", true, "agreePrivacy", true, "agreeAge", true);

        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isConflict());
    }

    /**
     * 필수 약관에 동의하지 않으면 가입이 막혀야 한다.
     *
     * <p>필드를 <b>아예 빼는</b> 경우까지 보는 이유: {@code SignupRequest} 가 primitive
     * boolean 이었다면 누락된 필드가 false 로 조용히 채워져 "동의 안 함"으로 가입이
     * 성립해버린다. 래퍼 Boolean + {@code @NotNull} 로 막아둔 것을 여기서 고정한다.
     */
    @Test
    void signup_without_required_agreements_returns_400() throws Exception {
        Map<String, Object> noAgreement = Map.of(
                "email", "carol@example.com", "password", "Passw0rd!23", "nickname", "Carol");

        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(noAgreement)))
                .andExpect(status().isBadRequest());

        Map<String, Object> declinedAge = Map.of(
                "email", "dave@example.com", "password", "Passw0rd!23", "nickname", "Dave",
                "agreeTos", true, "agreePrivacy", true, "agreeAge", false);

        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(declinedAge)))
                .andExpect(status().isBadRequest());
    }
}
