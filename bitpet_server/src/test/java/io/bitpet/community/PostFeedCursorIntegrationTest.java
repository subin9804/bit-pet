package io.bitpet.community;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.community.domain.PostMst;
import io.bitpet.community.dto.PostCreateRequest;
import io.bitpet.community.dto.PostFeedResponse;
import io.bitpet.community.dto.PostSummaryResponse;
import io.bitpet.community.repository.PostCategoryCdRepository;
import io.bitpet.community.repository.PostMstRepository;
import io.bitpet.community.service.KidsBoardPolicy;
import io.bitpet.community.service.PostService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 피드 커서 페이지네이션 (2026-11-17).
 * offset 방식은 스크롤 중 새 글이 올라오면 다음 묶음 첫 글이 겹쳤다 — 커서면 겹치지 않는다.
 * 카테고리를 콕 집어 부른다 — 다른 테스트가 남긴 글이 섞여도 이 카테고리 안에서만 본다.
 */
class PostFeedCursorIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PostService postService;
    @Autowired private PostMstRepository postRepository;
    @Autowired private PostCategoryCdRepository categoryRepository;

    @Test
    void new_post_while_scrolling_does_not_duplicate_or_skip() {
        Long user = signup();
        Long category = generalCategoryId();
        List<Long> before = new ArrayList<>();
        for (int i = 0; i < 5; i++) before.add(write(user, category, "글" + i));

        PostFeedResponse first = postService.listPosts(user, category, null, 2);
        assertThat(first.hasMore()).isTrue();

        // 첫 묶음을 본 뒤 누가 새 글을 쓴다 — offset 이면 여기서 한 칸씩 밀린다
        write(user, category, "새 글");

        List<Long> seen = new ArrayList<>(ids(first));
        Long cursor = first.nextCursor();
        while (cursor != null) {
            PostFeedResponse next = postService.listPosts(user, category, cursor, 2);
            seen.addAll(ids(next));
            cursor = next.nextCursor();
        }

        assertThat(new HashSet<>(seen)).hasSize(seen.size());   // 겹침 없음
        assertThat(seen).containsAll(before);                   // 빠짐 없음
    }

    @Test
    void pinned_posts_come_first_only_on_first_request() {
        Long user = signup();
        Long category = generalCategoryId();
        Long pinned = write(user, category, "고정");
        PostMst p = postRepository.findById(pinned).orElseThrow();
        p.setPinned(true);
        postRepository.save(p);
        for (int i = 0; i < 3; i++) write(user, category, "일반" + i);

        PostFeedResponse first = postService.listPosts(user, category, null, 2);
        assertThat(ids(first).getFirst()).isEqualTo(pinned);

        Set<Long> rest = new HashSet<>();
        Long cursor = first.nextCursor();
        while (cursor != null) {
            PostFeedResponse next = postService.listPosts(user, category, cursor, 2);
            rest.addAll(ids(next));
            cursor = next.nextCursor();
        }
        assertThat(rest).doesNotContain(pinned);
    }

    // -------------------------------------------------------------------------

    private List<Long> ids(PostFeedResponse r) {
        return r.content().stream().map(PostSummaryResponse::id).toList();
    }

    private Long write(Long user, Long category, String title) {
        return postService.createPost(user, new PostCreateRequest(category, title, "본문")).id();
    }

    /** 공지·어린이 게시판이 아닌 아무 게시판. 테스트마다 새로 만든 글만 비교하므로 겹쳐도 된다. */
    private Long generalCategoryId() {
        return categoryRepository.findAllByOrderByDisplayOrderAsc().stream()
                .filter(c -> !"NOTICE".equals(c.getCode())
                        && !KidsBoardPolicy.KIDS_CATEGORY_CODE.equals(c.getCode()))
                .findFirst().orElseThrow().getId();
    }

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "feedcur" + n + "@example.com", "Passw0rd!23", "feedcur" + n, null,
                true, true, true, null, false, null)).id();
    }
}
