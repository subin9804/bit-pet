package io.bitpet.community;

import io.bitpet.auth.dto.ChildCreateRequest;
import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.auth.service.GuardianService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.community.dto.PostCreateRequest;
import io.bitpet.community.repository.PostCategoryCdRepository;
import io.bitpet.community.service.KidsBoardPolicy;
import io.bitpet.community.service.PostService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 자녀 계정 커뮤니티 허용 스위치 (V2, 2026-11-10 — Play 가족 정책).
 * 기본 꺼짐 · 꺼져 있으면 읽기·쓰기 전부 막힘 · 남의 자녀는 못 바꿈.
 */
class ChildCommunityToggleIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private GuardianService guardianService;
    @Autowired private AuthService authService;
    @Autowired private PostService postService;
    @Autowired private PostCategoryCdRepository categoryRepository;

    @Test
    void child_community_is_off_by_default_and_blocks_read_and_write() {
        Long guardian = signup();
        Long child = createChild(guardian, null);

        assertThat(authService.getMe(child).communityAllowed()).isFalse();
        assertDisabled(() -> postService.listCategories(child));
        assertDisabled(() -> postService.listPosts(child, null, PageRequest.of(0, 10)));
        assertDisabled(() -> postService.createPost(child, kidsPost()));
        // 성인은 스위치와 무관하다
        assertThat(authService.getMe(guardian).communityAllowed()).isTrue();
    }

    @Test
    void guardian_turns_on_then_off() {
        Long guardian = signup();
        Long child = createChild(guardian, null);

        assertThat(guardianService.changeCommunity(guardian, child, true).communityEnabled()).isTrue();
        assertThat(authService.getMe(child).communityAllowed()).isTrue();
        Long postId = postService.createPost(child, kidsPost()).id();
        assertThat(postService.listCategories(child)).isNotEmpty();

        guardianService.changeCommunity(guardian, child, false);
        assertDisabled(() -> postService.getPost(child, postId));
        // 자기 글 삭제는 끈 뒤에도 된다
        postService.deletePost(child, postId);
    }

    @Test
    void can_be_enabled_at_creation() {
        Long guardian = signup();
        Long child = createChild(guardian, true);
        assertThat(authService.getMe(child).communityAllowed()).isTrue();
    }

    @Test
    void other_guardian_cannot_toggle() {
        Long guardian = signup();
        Long stranger = signup();
        Long child = createChild(guardian, null);

        assertThatThrownBy(() -> guardianService.changeCommunity(stranger, child, true))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.CHILD_NOT_FOUND);
    }

    // -------------------------------------------------------------------------

    private void assertDisabled(org.assertj.core.api.ThrowableAssert.ThrowingCallable call) {
        assertThatThrownBy(call)
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.CHILD_COMMUNITY_DISABLED);
    }

    private PostCreateRequest kidsPost() {
        Long kidsId = categoryRepository.findAllByOrderByDisplayOrderAsc().stream()
                .filter(c -> KidsBoardPolicy.KIDS_CATEGORY_CODE.equals(c.getCode()))
                .findFirst().orElseThrow().getId();
        return new PostCreateRequest(kidsId, "우리 게코", "오늘 밥 잘 먹었어요");
    }

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "ccom" + n + "@example.com", "Passw0rd!23", "ccomparent" + n, null,
                true, true, true, false, null)).id();
    }

    private Long createChild(Long guardian, Boolean communityEnabled) {
        int n = SEQ.incrementAndGet();
        return guardianService.createChild(guardian, new ChildCreateRequest(
                "ccomkid" + n + "@example.com", "Passw0rd!23", "ccomkid" + n, null,
                LocalDate.now().minusYears(10), true, false, communityEnabled)).id();
    }
}
