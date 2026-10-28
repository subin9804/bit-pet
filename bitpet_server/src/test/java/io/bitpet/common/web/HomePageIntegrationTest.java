package io.bitpet.common.web;

import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.forwardedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** tailog.me 홈 (static/index.html) 은 로그인 없이 열려야 한다 — 앱 설치 유도 페이지. */
class HomePageIntegrationTest extends IntegrationTestBase {

    @Test
    void root_forwards_to_landing_page() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(forwardedUrl("index.html"));
    }

    @Test
    void landing_page_is_public_html() throws Exception {
        // 정적 리소스는 Content-Type 에 charset 이 없다 — 브라우저는 <meta charset="utf-8"> 을 따른다
        String html = mockMvc.perform(get("/index.html"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith("text/html"))
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);

        assertThat(html).contains("<meta charset=\"utf-8\">",
                "쉽고 편한 기록", "케어 루틴 알림", "개체별 기록 관리");
    }
}
