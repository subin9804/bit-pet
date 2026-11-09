package io.bitpet.common.appversion;

import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** 강제 업데이트 기준 — 토큰 없이 열려 있어야 한다 (구버전 앱은 로그인부터 못 할 수 있다). */
class AppVersionIntegrationTest extends IntegrationTestBase {

    @Test
    void version_is_public_and_returns_platform_values() throws Exception {
        mockMvc.perform(get("/api/v1/app/version").param("platform", "android"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.minVersion").value("1.0.0"))
                .andExpect(jsonPath("$.data.storeUrl").value("https://play.google.com/store/apps/details?id=me.tailog.app"));

        mockMvc.perform(get("/api/v1/app/version").param("platform", "ios"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.minVersion").exists());
    }
}
