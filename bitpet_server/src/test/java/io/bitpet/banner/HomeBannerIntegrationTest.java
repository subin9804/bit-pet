package io.bitpet.banner;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.bitpet.auth.domain.AdminRoleRls;
import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.repository.AdminRoleRlsRepository;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.auth.service.AuthService;
import io.bitpet.banner.domain.BannerLinkType;
import io.bitpet.banner.dto.HomeBannerRequest;
import io.bitpet.banner.dto.HomeBannerResponse;
import io.bitpet.banner.repository.HomeBannerMstRepository;
import io.bitpet.banner.service.HomeBannerService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.forwardedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 홈 배너 — 앱에 무엇이 내려가는지(기간·켜짐·자녀 계정), 그리고 관리 API 가 어드민만 통과시키는지.
 */
class HomeBannerIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();
    private static final String PASSWORD = "Passw0rd!23";

    @Autowired private AuthService authService;
    @Autowired private HomeBannerService bannerService;
    @Autowired private HomeBannerMstRepository bannerRepository;
    @Autowired private UserMstRepository userRepository;
    @Autowired private AdminRoleRlsRepository adminRepository;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private ObjectMapper objectMapper;

    @BeforeEach
    void clean() {
        bannerRepository.deleteAll();
    }

    @Test
    void 앱에는_켜져있고_기간_안인_배너만_순서대로_내려간다() {
        Long user = signup();
        Instant now = Instant.now();
        bannerService.create(req("둘째", BannerLinkType.NONE, null, null, null, 2, true));
        bannerService.create(req("첫째", BannerLinkType.ROUTE, "/community", null, null, 1, true));
        bannerService.create(req("꺼짐", BannerLinkType.NONE, null, null, null, 0, false));
        bannerService.create(req("예약", BannerLinkType.NONE, null, now.plus(1, ChronoUnit.DAYS), null, 0, true));
        bannerService.create(req("끝남", BannerLinkType.NONE, null,
                now.minus(2, ChronoUnit.DAYS), now.minus(1, ChronoUnit.DAYS), 0, true));

        List<HomeBannerResponse> live = bannerService.listLive(user);

        assertThat(live).extracting(HomeBannerResponse::title).containsExactly("첫째", "둘째");
        assertThat(live.get(0).linkValue()).isEqualTo("/community");
        assertThat(bannerService.listAll()).hasSize(5);
    }

    @Test
    void 자녀_계정에는_외부_링크_배너가_빠진다() {
        Long adult = signup();
        Long child = signup();
        jdbc.update("UPDATE user_mst SET birth_date = ? WHERE id = ?", LocalDate.now().minusYears(10), child);
        bannerService.create(req("앱안", BannerLinkType.ROUTE, "/routines", null, null, 0, true));
        bannerService.create(req("바깥", BannerLinkType.URL, "https://tailog.me/event", null, null, 1, true));

        assertThat(bannerService.listLive(adult)).extracting(HomeBannerResponse::title).containsExactly("앱안", "바깥");
        assertThat(bannerService.listLive(child)).extracting(HomeBannerResponse::title).containsExactly("앱안");
    }

    @Test
    void 링크_형식과_기간을_검증한다() {
        assertThatThrownBy(() -> bannerService.create(req("x", BannerLinkType.ROUTE, "community", null, null, 0, true)))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> bannerService.create(req("x", BannerLinkType.URL, "http://evil", null, null, 0, true)))
                .isInstanceOf(BusinessException.class);
        Instant t = Instant.now();
        assertThatThrownBy(() -> bannerService.create(req("x", BannerLinkType.NONE, null, t, t, 0, true)))
                .isInstanceOf(BusinessException.class);
        // 남의 사진 키를 끌어다 쓰면 배너 삭제 때 그 사진이 지워진다
        assertThatThrownBy(() -> bannerService.create(new HomeBannerRequest("x", null, null, "pets/1/a.jpg",
                BannerLinkType.NONE, null, null, null, 0, true)))
                .isInstanceOf(BusinessException.class);
        // NONE 이면 링크 값은 버린다 (DB CHECK 와 맞춘다)
        assertThat(bannerService.create(req("x", BannerLinkType.NONE, "/oops", null, null, 0, true)).linkValue()).isNull();
    }

    @Test
    void 관리_API는_어드민만_통과한다() throws Exception {
        String plainEmail = "bnplain" + SEQ.incrementAndGet() + "@example.com";
        signupWithEmail(plainEmail);
        String plain = login(plainEmail);
        String adminEmail = "bnadmin" + SEQ.incrementAndGet() + "@example.com";
        Long adminId = signupWithEmail(adminEmail);
        adminRepository.save(AdminRoleRls.builder()
                .user(userRepository.getReferenceById(adminId)).role("SUPER_ADMIN").build());
        String admin = login(adminEmail);

        String body = objectMapper.writeValueAsString(req("새 배너", BannerLinkType.NONE, null, null, null, 0, true));

        mockMvc.perform(get("/api/v1/admin/banners").header("Authorization", "Bearer " + plain))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/v1/admin/banners").header("Authorization", "Bearer " + plain)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isForbidden());
        mockMvc.perform(multipart("/api/v1/admin/banners/image")
                        .file(new MockMultipartFile("file", "a.png", "image/png", new byte[]{1}))
                        .header("Authorization", "Bearer " + plain))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/api/v1/admin/banners").header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.live").value(true));
        // 이미지 형식이 아니면 S3 에 닿기 전에 400
        mockMvc.perform(multipart("/api/v1/admin/banners/image")
                        .file(new MockMultipartFile("file", "a.txt", "text/plain", new byte[]{1}))
                        .header("Authorization", "Bearer " + admin))
                .andExpect(status().isBadRequest());

        // 앱 쪽 — 로그인한 누구나
        mockMvc.perform(get("/api/v1/home/banners").header("Authorization", "Bearer " + plain))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].title").value("새 배너"));
        mockMvc.perform(get("/api/v1/home/banners")).andExpect(status().isUnauthorized());
    }

    @Test
    void 관리_페이지는_로그인_없이_열린다() throws Exception {
        mockMvc.perform(get("/admin/banners"))
                .andExpect(status().isOk())
                .andExpect(forwardedUrl("/admin/banners.html"));
    }

    private static HomeBannerRequest req(String title, BannerLinkType type, String link,
                                         Instant start, Instant end, int order, boolean active) {
        return new HomeBannerRequest(title, null, null, null, type, link, start, end, order, active);
    }

    private Long signup() {
        return signupWithEmail("banner" + SEQ.incrementAndGet() + "@example.com");
    }

    private Long signupWithEmail(String email) {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                email, PASSWORD, "bnuser" + n, null,
                true, true, true, null, false, null)).id();
    }

    private String login(String email) throws Exception {
        String res = mockMvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", email, "password", PASSWORD))))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(res).at("/data/accessToken").asText();
    }
}
