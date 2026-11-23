package io.bitpet.community;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.dto.UpdateMeRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.community.dto.CommentCreateRequest;
import io.bitpet.community.dto.MyCommentResponse;
import io.bitpet.community.dto.PostCreateRequest;
import io.bitpet.community.dto.PostSummaryResponse;
import io.bitpet.community.repository.PostCategoryCdRepository;
import io.bitpet.community.service.BlockService;
import io.bitpet.community.service.KidsBoardPolicy;
import io.bitpet.community.service.PostService;
import io.bitpet.pet.service.PetService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;

import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 남의 프로필 > 작성한 글·댓글 (2026-11-23). 피드와 같은 차단 규칙이 걸리는지 본다.
 */
class UserActivityIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PostService postService;
    @Autowired private PetService petService;
    @Autowired private BlockService blockService;
    @Autowired private PostCategoryCdRepository categoryRepository;

    @Test
    void 남이_쓴_글과_댓글을_볼_수_있다() {
        Long writer = signup();
        Long viewer = signup();
        Long category = generalCategoryId();
        Long postId = postService.createPost(writer,
                new PostCreateRequest(category, "작성자 글", "본문")).id();
        postService.createComment(writer, postId, new CommentCreateRequest(null, "작성자 댓글"));

        var posts = postService.listUserPosts(viewer, writer, PageRequest.of(0, 20));
        assertThat(posts.getContent()).extracting(PostSummaryResponse::id).containsExactly(postId);

        var comments = postService.listUserComments(viewer, writer, PageRequest.of(0, 20));
        assertThat(comments.getContent()).extracting(MyCommentResponse::content)
                .containsExactly("작성자 댓글");
        assertThat(comments.getContent().get(0).postTitle()).isEqualTo("작성자 글");
    }

    @Test
    void 차단_관계면_방향과_무관하게_프로필과_활동을_막는다() {
        Long writer = signup();
        Long viewer = signup();
        blockService.block(writer, viewer);   // 작성자가 보는 사람을 차단

        assertThatThrownBy(() -> postService.listUserPosts(viewer, writer, PageRequest.of(0, 20)))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode").isEqualTo(ErrorCode.USER_HIDDEN);
        assertThatThrownBy(() -> petService.getUserProfile(viewer, writer))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode").isEqualTo(ErrorCode.USER_HIDDEN);
    }

    @Test
    void 가계도_닉네임_비공개여도_프로필은_열리고_개체만_비운다() {
        Long owner = signup();
        Long viewer = signup();
        authService.updateMe(owner, new UpdateMeRequest(null, null, null, false));

        var profile = petService.getUserProfile(viewer, owner);
        assertThat(profile.petsHidden()).isTrue();
        assertThat(profile.publicPets()).isEmpty();

        // 본인에게는 가리지 않는다
        assertThat(petService.getUserProfile(owner, owner).petsHidden()).isFalse();
    }

    // -------------------------------------------------------------------------

    private Long generalCategoryId() {
        return categoryRepository.findAllByOrderByDisplayOrderAsc().stream()
                .filter(c -> !"NOTICE".equals(c.getCode())
                        && !KidsBoardPolicy.KIDS_CATEGORY_CODE.equals(c.getCode()))
                .findFirst().orElseThrow().getId();
    }

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "uact" + n + "@example.com", "Passw0rd!23", "uact" + n, null,
                true, true, true, null, false, null)).id();
    }
}
