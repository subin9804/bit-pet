package io.bitpet.common.legal;

import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** 약관 공개 페이지는 로그인 없이 열려야 한다 — 스토어 심사관은 토큰이 없다. */
class LegalPageIntegrationTest extends IntegrationTestBase {

    @Test
    void privacy_policy_is_public_html() throws Exception {
        mockMvc.perform(get("/legal/privacy"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith("text/html"))
                .andExpect(content().string(containsString("개인정보 처리방침")))
                .andExpect(content().string(containsString("시행일 2026-08-19")))
                .andExpect(content().string(containsString("privacy@tailog.me")));
    }

    @Test
    void index_lists_documents() throws Exception {
        mockMvc.perform(get("/legal"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("/legal/tos")));
    }

    @Test
    void unknown_document_is_404() throws Exception {
        mockMvc.perform(get("/legal/nope")).andExpect(status().isNotFound());
    }
}
