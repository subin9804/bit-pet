package io.bitpet.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.bitpet.auth.mail.MailSender;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.ResultActions;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 이메일 가입 인증 (2026-11-06) — 다른 테스트는 인증을 끄고 가입하므로 여기서만 켠다.
 * 허용 도메인은 application-test.yml 목록(example.com·naver.com·gmail.com)을 쓴다.
 */
@TestPropertySource(properties = "bitpet.signup.email-verification-required=true")
class SignupEmailVerificationIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private ObjectMapper objectMapper;
    @MockitoBean private MailSender mailSender;

    @Test
    void code_then_token_then_signup_succeeds_and_token_is_single_use() throws Exception {
        String email = unique("naver.com");
        String token = verifiedToken(email);

        signup(email, token).andExpect(status().isCreated());

        // 같은 토큰으로 다른 주소·같은 주소 모두 재사용 불가
        signup(unique("naver.com"), token).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("SIGNUP_EMAIL_NOT_VERIFIED"));
    }

    @Test
    void signup_without_token_is_rejected() throws Exception {
        signup(unique("gmail.com"), null)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("SIGNUP_EMAIL_NOT_VERIFIED"));
    }

    @Test
    void token_for_another_address_is_rejected() throws Exception {
        String token = verifiedToken(unique("gmail.com"));

        signup(unique("gmail.com"), token)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("SIGNUP_EMAIL_NOT_VERIFIED"));
    }

    @Test
    void disallowed_domain_gets_no_code_and_check_email_says_so() throws Exception {
        String email = unique("mailinator.com");

        post("/api/v1/auth/signup/email-code", Map.of("email", email))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("AUTH_EMAIL_DOMAIN_NOT_ALLOWED"));
        verify(mailSender, never()).sendSignupVerificationCode(eq(email), anyString());

        mockMvc.perform(get("/api/v1/auth/check-email").param("email", email))
                .andExpect(jsonPath("$.data.available").value(false))
                .andExpect(jsonPath("$.data.domainAllowed").value(false));
        mockMvc.perform(get("/api/v1/auth/check-email").param("email", unique("Naver.COM")))
                .andExpect(jsonPath("$.data.available").value(true))
                .andExpect(jsonPath("$.data.domainAllowed").value(true));
    }

    @Test
    void resend_within_cooldown_is_429() throws Exception {
        String email = unique("naver.com");
        post("/api/v1/auth/signup/email-code", Map.of("email", email)).andExpect(status().isOk());
        post("/api/v1/auth/signup/email-code", Map.of("email", email))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.error.code").value("SIGNUP_CODE_COOLDOWN"));
    }

    @Test
    void too_many_wrong_codes_burns_the_code() throws Exception {
        String email = unique("naver.com");
        String code = sendCode(email);
        String wrong = code.equals("000000") ? "111111" : "000000";

        for (int i = 0; i < 4; i++) {
            verifyCode(email, wrong).andExpect(jsonPath("$.error.code").value("SIGNUP_CODE_INVALID"));
        }
        verifyCode(email, wrong).andExpect(jsonPath("$.error.code").value("SIGNUP_CODE_TOO_MANY_ATTEMPTS"));
        // 맞는 코드도 이제는 안 통한다
        verifyCode(email, code).andExpect(jsonPath("$.error.code").value("SIGNUP_CODE_NOT_FOUND"));
    }

    @Test
    void already_registered_address_gets_409_instead_of_code() throws Exception {
        String email = unique("naver.com");
        signup(email, verifiedToken(email)).andExpect(status().isCreated());

        post("/api/v1/auth/signup/email-code", Map.of("email", email.toUpperCase()))
                .andExpect(status().isConflict());
    }

    private String unique(String domain) {
        return "verify" + SEQ.incrementAndGet() + "-" + System.nanoTime() + "@" + domain;
    }

    private String sendCode(String email) throws Exception {
        post("/api/v1/auth/signup/email-code", Map.of("email", email)).andExpect(status().isOk());
        ArgumentCaptor<String> code = ArgumentCaptor.forClass(String.class);
        verify(mailSender).sendSignupVerificationCode(eq(email), code.capture());
        return code.getValue();
    }

    private ResultActions verifyCode(String email, String code) throws Exception {
        return post("/api/v1/auth/signup/email-code/verify", Map.of("email", email, "code", code));
    }

    private String verifiedToken(String email) throws Exception {
        String body = verifyCode(email, sendCode(email))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body).at("/data/verificationToken").asText();
    }

    private ResultActions signup(String email, String token) throws Exception {
        Map<String, Object> body = new HashMap<>();
        body.put("email", email);
        body.put("password", "Passw0rd!23");
        body.put("nickname", "v" + SEQ.incrementAndGet());
        body.put("agreeTos", true);
        body.put("agreePrivacy", true);
        body.put("agreeAge", true);
        body.put("emailVerificationToken", token);
        return post("/api/v1/auth/signup", body);
    }

    private ResultActions post(String url, Map<String, ?> body) throws Exception {
        return mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(url)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)));
    }
}
