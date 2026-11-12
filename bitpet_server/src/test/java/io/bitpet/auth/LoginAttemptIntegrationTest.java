package io.bitpet.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;

import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 로그인 실패 잠금 (2026-11-09). 5번 틀리면 10분 동안 그 이메일은 맞는 비밀번호도 받지 않는다.
 */
class LoginAttemptIntegrationTest extends IntegrationTestBase {

    private static final String PASSWORD = "Passw0rd!23";
    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private ObjectMapper objectMapper;
    @Autowired private AuthService authService;
    @Autowired private LoginAttemptStore loginAttemptStore;

    @Test
    void five_failures_lock_the_account_even_for_the_right_password() throws Exception {
        String email = signup();
        for (int i = 0; i < LoginAttemptStore.MAX_FAILURES; i++) {
            login(email, "wrong-password").andExpect(status().isUnauthorized());
        }

        login(email, PASSWORD)
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.error.code").value("AUTH_LOGIN_LOCKED"));
        // 대소문자를 바꿔도 같은 잠금이다
        login(email.toUpperCase(), PASSWORD).andExpect(status().isTooManyRequests());

        loginAttemptStore.reset(email); // 10분 경과 대신
        login(email, PASSWORD).andExpect(status().isOk());
    }

    @Test
    void success_clears_earlier_failures() throws Exception {
        String email = signup();
        for (int i = 0; i < LoginAttemptStore.MAX_FAILURES - 1; i++) {
            login(email, "wrong-password").andExpect(status().isUnauthorized());
        }
        login(email, PASSWORD).andExpect(status().isOk());

        // 성공으로 카운트가 지워졌으니 다시 4번 틀려도 잠기지 않는다
        for (int i = 0; i < LoginAttemptStore.MAX_FAILURES - 1; i++) {
            login(email, "wrong-password").andExpect(status().isUnauthorized());
        }
        login(email, PASSWORD).andExpect(status().isOk());
    }

    @Test
    void unknown_email_locks_the_same_way() throws Exception {
        // 잠금 여부로 가입 여부를 알 수 없어야 한다
        String email = "nobody" + SEQ.incrementAndGet() + "@example.com";
        for (int i = 0; i < LoginAttemptStore.MAX_FAILURES; i++) {
            login(email, "whatever").andExpect(status().isUnauthorized());
        }
        login(email, "whatever").andExpect(status().isTooManyRequests());
    }

    // -------------------------------------------------------------------------

    private String signup() {
        int n = SEQ.incrementAndGet();
        String email = "lock" + n + "@example.com";
        authService.signup(new SignupRequest(
                email, PASSWORD, "lockuser" + n, null, true, true, true, null, false, null));
        return email;
    }

    private ResultActions login(String email, String password) throws Exception {
        return mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("email", email, "password", password))));
    }
}
