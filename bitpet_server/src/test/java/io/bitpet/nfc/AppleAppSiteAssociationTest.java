package io.bitpet.nfc;

import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@TestPropertySource(properties = "bitpet.apple.team-id=ABCDE12345")
class AppleAppSiteAssociationTest extends IntegrationTestBase {

    @Test
    void serves_json_without_login_for_tag_paths_only() throws Exception {
        mockMvc.perform(get("/.well-known/apple-app-site-association"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.applinks.details[0].appIDs[0]").value("ABCDE12345.me.tailog.app"))
                .andExpect(jsonPath("$.applinks.details[0].components[0]['/']").value("/t/*"));
    }
}
