package io.bitpet.community.repository;

import io.bitpet.community.domain.PostCommentDtl;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface PostCommentDtlRepository extends JpaRepository<PostCommentDtl, Long> {

    List<PostCommentDtl> findAllByPostIdOrderByCreatedAtAsc(Long postId);

    // 마이페이지 '내 댓글'. @SQLRestriction 덕에 소프트 삭제된 내 댓글은 빠진다.
    Page<PostCommentDtl> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    /**
     * 남의 프로필 > 작성한 댓글 (2026-11-23).
     *
     * <p>'내 댓글'과 달리 <b>보는 사람이 열 수 있는 글에 달린 것만</b> 싣는다 — 원글이 삭제됐거나
     * (PostMst 의 @SQLRestriction), 보는 사람에게 막힌 게시판(어린이)이거나, 보는 사람과 차단 관계인
     * 사람의 글이면 뺀다. 눌러도 열리지 않을 줄을 보여줘 봐야 오류만 난다.
     * 제외 값은 피드와 같은 센티널(-1) 규칙.
     */
    @Query(value = "SELECT c FROM PostCommentDtl c, PostMst p WHERE p.id = c.postId "
            + "AND c.userId = :userId AND p.categoryId <> :excludeCategoryId "
            + "AND p.userId NOT IN :hiddenUserIds ORDER BY c.id DESC",
            countQuery = "SELECT COUNT(c) FROM PostCommentDtl c, PostMst p WHERE p.id = c.postId "
            + "AND c.userId = :userId AND p.categoryId <> :excludeCategoryId "
            + "AND p.userId NOT IN :hiddenUserIds")
    Page<PostCommentDtl> findVisibleByUserId(@Param("userId") Long userId,
                                             @Param("excludeCategoryId") Long excludeCategoryId,
                                             @Param("hiddenUserIds") Collection<Long> hiddenUserIds,
                                             Pageable pageable);
}
