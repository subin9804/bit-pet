package io.bitpet.community;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.bitpet.auth.domain.AdminRoleRls;
import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.repository.AdminRoleRlsRepository;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.community.domain.PostReportDtl;
import io.bitpet.community.domain.ReportAction;
import io.bitpet.community.domain.ReportReason;
import io.bitpet.community.domain.ReportStatus;
import io.bitpet.community.domain.ReportTargetType;
import io.bitpet.community.domain.SuspensionDuration;
import io.bitpet.community.dto.CommentCreateRequest;
import io.bitpet.community.dto.PostCreateRequest;
import io.bitpet.community.dto.ReportCreateRequest;
import io.bitpet.community.dto.ReportHandleRequest;
import io.bitpet.community.dto.ReportResponse;
import io.bitpet.community.dto.SuspensionResponse;
import io.bitpet.community.repository.PostCategoryCdRepository;
import io.bitpet.community.repository.PostReportDtlRepository;
import io.bitpet.community.service.PostService;
import io.bitpet.community.service.ReportService;
import io.bitpet.community.service.SuspensionService;
import io.bitpet.inquiry.domain.InquiryCategory;
import io.bitpet.inquiry.dto.InquiryCreateRequest;
import io.bitpet.inquiry.service.InquiryAdminService;
import io.bitpet.inquiry.service.InquiryService;
import io.bitpet.notification.repository.PushBroadcastDtlRepository;
import io.bitpet.support.IntegrationTestBase;
import org.assertj.core.api.ThrowableAssert.ThrowingCallable;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;

import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.forwardedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 운영 도구 — 신고로 커뮤니티 정지, 가림 해제, 문의함, 전체 푸시 대상, 그리고 관리 API 가 어드민만 통과하는지.
 */
class ModerationAdminIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();
    private static final String PASSWORD = "Passw0rd!23";

    @Autowired private AuthService authService;
    @Autowired private PostService postService;
    @Autowired private ReportService reportService;
    @Autowired private SuspensionService suspensionService;
    @Autowired private InquiryService inquiryService;
    @Autowired private InquiryAdminService inquiryAdminService;
    @Autowired private PostCategoryCdRepository categoryRepository;
    @Autowired private PostReportDtlRepository reportRepository;
    @Autowired private PushBroadcastDtlRepository broadcastRepository;
    @Autowired private UserMstRepository userRepository;
    @Autowired private AdminRoleRlsRepository adminRepository;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void 정지되면_커뮤니티_쓰기만_막히고_해제하면_풀린다() {
        Long admin = admin();
        Long writer = signup(false);
        Long reporter = signup(false);
        Long postId = postService.createPost(writer, freePost()).id();
        // 신고자는 작성자를 자동 차단하므로, 정지 확인은 상관없는 사람의 글로 한다
        Long otherPost = postService.createPost(signup(false), freePost()).id();

        ReportResponse handled = reportService.handle(admin, reportPost(reporter, postId),
                new ReportHandleRequest(ReportStatus.RESOLVED, ReportAction.SUSPEND, "도배", SuspensionDuration.DAY_7));

        // 신고된 글은 같이 가려진다
        assertThat(handled.targetBlinded()).isTrue();
        assertSuspended(() -> postService.createPost(writer, freePost()));
        assertSuspended(() -> postService.createComment(writer, otherPost, new CommentCreateRequest(null, "댓글")));
        assertSuspended(() -> postService.toggleLike(writer, otherPost));
        assertSuspended(() -> reportService.report(writer,
                new ReportCreateRequest(ReportTargetType.POST, otherPost, ReportReason.SPAM, null)));
        // 읽기는 된다
        postService.getPost(writer, otherPost);

        SuspensionResponse s = suspensionService.listActive().stream()
                .filter(r -> r.userId().equals(writer)).findFirst().orElseThrow();
        assertThat(s.endsAt()).isNotNull();
        suspensionService.release(s.id(), admin);

        postService.createPost(writer, freePost());
        assertThat(suspensionService.listActive()).noneMatch(r -> r.userId().equals(writer));
    }

    @Test
    void 정지는_위반_인정과_기간이_있어야_한다() {
        Long admin = admin();
        Long writer = signup(false);
        Long reporter = signup(false);
        Long reportId = reportPost(reporter, postService.createPost(writer, freePost()).id());

        assertThatThrownBy(() -> reportService.handle(admin, reportId,
                new ReportHandleRequest(ReportStatus.RESOLVED, ReportAction.SUSPEND, null, null)))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> reportService.handle(admin, reportId,
                new ReportHandleRequest(ReportStatus.REJECTED, ReportAction.SUSPEND, null, SuspensionDuration.DAY_1)))
                .isInstanceOf(BusinessException.class);
        // 실패한 처리는 흔적을 남기지 않는다
        postService.createPost(writer, freePost());
    }

    @Test
    void 가린_글은_되돌릴_수_있다() {
        Long admin = admin();
        Long writer = signup(false);
        Long reporter = signup(false);
        Long postId = postService.createPost(writer, freePost()).id();
        Long reportId = reportPost(reporter, postId);

        assertThat(reportService.handle(admin, reportId,
                new ReportHandleRequest(ReportStatus.RESOLVED, ReportAction.BLIND, null, null)).targetBlinded()).isTrue();
        assertThat(reportService.unblind(reportId).targetBlinded()).isFalse();
        assertThat(postService.getPost(signup(false), postId).blinded()).isFalse();
    }

    @Test
    void 문의함은_분류로_거르고_작성자를_보여준다() {
        Long user = signup(false);
        inquiryService.create(user, new InquiryCreateRequest(InquiryCategory.BUG, "앱이 꺼져요", "1.0.0", "android", "14"));
        inquiryService.create(user, new InquiryCreateRequest(InquiryCategory.SUGGESTION, "다크모드", null, null, null));

        var bugs = inquiryAdminService.list(InquiryCategory.BUG, PageRequest.of(0, 50)).getContent();
        assertThat(bugs).allMatch(q -> q.category() == InquiryCategory.BUG);
        assertThat(bugs).anySatisfy(q -> {
            assertThat(q.userId()).isEqualTo(user);
            assertThat(q.content()).isEqualTo("앱이 꺼져요");
            assertThat(q.nickname()).isNotBlank();
            assertThat(q.platform()).isEqualTo("android");
        });
        assertThat(inquiryAdminService.list(null, PageRequest.of(0, 50)).getContent())
                .filteredOn(q -> q.userId().equals(user)).hasSize(2);
    }

    @Test
    void 마케팅_푸시는_수신_동의자만_받는다() {
        Long agreed = signup(true);
        Long declined = signup(false);

        assertThat(broadcastRepository.findAllActiveUserIds()).contains(agreed, declined);
        assertThat(broadcastRepository.findMarketingConsentedUserIds()).contains(agreed).doesNotContain(declined);
    }

    @Test
    void 관리_API는_어드민만_통과한다() throws Exception {
        String plainEmail = "modplain" + SEQ.incrementAndGet() + "@example.com";
        signupWithEmail(plainEmail, false);
        String plain = login(plainEmail);
        String modEmail = "modmod" + SEQ.incrementAndGet() + "@example.com";
        grant(signupWithEmail(modEmail, false), "MODERATOR");
        String mod = login(modEmail);

        for (String path : new String[]{"/api/v1/admin/suspensions", "/api/v1/admin/inquiries",
                "/api/v1/admin/push/preview", "/api/v1/admin/push/broadcasts"}) {
            mockMvc.perform(get(path).header("Authorization", "Bearer " + plain)).andExpect(status().isForbidden());
        }
        mockMvc.perform(post("/api/v1/admin/reports/1/unblind").header("Authorization", "Bearer " + plain))
                .andExpect(status().isForbidden());

        // 운영자(MODERATOR)는 신고·정지·문의까지, 전체 푸시는 최고 관리자만
        mockMvc.perform(get("/api/v1/admin/suspensions").header("Authorization", "Bearer " + mod))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/v1/admin/inquiries").header("Authorization", "Bearer " + mod))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/v1/admin/push/broadcast").header("Authorization", "Bearer " + mod)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("title", "t", "body", "b", "marketing", false))))
                .andExpect(status().isForbidden());
    }

    @Test
    void 관리_페이지는_로그인_없이_열린다() throws Exception {
        for (String page : new String[]{"reports", "inquiries", "push"}) {
            mockMvc.perform(get("/admin/" + page))
                    .andExpect(status().isOk())
                    .andExpect(forwardedUrl("/admin/" + page + ".html"));
        }
        for (String home : new String[]{"/admin", "/admin/"}) {
            mockMvc.perform(get(home))
                    .andExpect(status().isOk())
                    .andExpect(forwardedUrl("/admin/index.html"));
        }
        mockMvc.perform(get("/admin/admin.js")).andExpect(status().isOk());
        mockMvc.perform(get("/admin/admin.css")).andExpect(status().isOk());
    }

    // -------------------------------------------------------------------------

    private void assertSuspended(ThrowingCallable call) {
        assertThatThrownBy(call)
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.COMMUNITY_SUSPENDED);
    }

    private Long reportPost(Long reporter, Long postId) {
        reportService.report(reporter, new ReportCreateRequest(ReportTargetType.POST, postId, ReportReason.SPAM, null));
        return reportRepository.findAll().stream()
                .filter(r -> r.getTargetType() == ReportTargetType.POST && r.getTargetId().equals(postId))
                .map(PostReportDtl::getId).findFirst().orElseThrow();
    }

    private PostCreateRequest freePost() {
        Long freeId = categoryRepository.findAllByOrderByDisplayOrderAsc().stream()
                .filter(c -> !"NOTICE".equals(c.getCode()) && !"KIDS".equals(c.getCode()))
                .findFirst().orElseThrow().getId();
        return new PostCreateRequest(freeId, "제목", "본문");
    }

    private Long admin() {
        Long id = signup(false);
        grant(id, "SUPER_ADMIN");
        return id;
    }

    private void grant(Long userId, String role) {
        adminRepository.save(AdminRoleRls.builder().user(userRepository.getReferenceById(userId)).role(role).build());
    }

    private Long signup(boolean marketing) {
        return signupWithEmail("mod" + SEQ.incrementAndGet() + "@example.com", marketing);
    }

    private Long signupWithEmail(String email, boolean marketing) {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                email, PASSWORD, "moduser" + n, null,
                true, true, true, null, marketing, null)).id();
    }

    private String login(String email) throws Exception {
        String res = mockMvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", email, "password", PASSWORD))))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(res).at("/data/accessToken").asText();
    }
}
