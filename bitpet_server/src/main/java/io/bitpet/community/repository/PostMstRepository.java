package io.bitpet.community.repository;

import io.bitpet.community.domain.PostMst;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;

public interface PostMstRepository extends JpaRepository<PostMst, Long> {

    // 공지(pinned) 우선, 그다음 최신순. Pageable 의 sort 는 무시하고 page/size 만 사용한다.
    @Query("SELECT p FROM PostMst p "
            + "ORDER BY CASE WHEN p.pinnedYn = 'Y' THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<PostMst> findAllOrdered(Pageable pageable);

    @Query("SELECT p FROM PostMst p WHERE p.categoryId = :categoryId "
            + "ORDER BY CASE WHEN p.pinnedYn = 'Y' THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<PostMst> findByCategoryOrdered(@Param("categoryId") Long categoryId, Pageable pageable);

    Page<PostMst> findByUserId(Long userId, Pageable pageable);

    // ── 차단 필터 버전 ──────────────────────────────────────────────────────────
    // 위 두 쿼리와 정렬이 완전히 같아야 한다. 차단이 있고 없고에 따라 피드 순서가 달라지면
    // 사용자가 눈치챈다 — 차단은 조용히 빠지는 것이어야 한다.
    // ⚠️ JPQL `NOT IN (:list)` 는 빈 리스트에서 터진다. 부르는 쪽이 비었을 때 위 쿼리로 분기할 것.

    @Query("SELECT p FROM PostMst p WHERE p.userId NOT IN :blockedUserIds "
            + "ORDER BY CASE WHEN p.pinnedYn = 'Y' THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<PostMst> findAllOrderedExcluding(
            @Param("blockedUserIds") Collection<Long> blockedUserIds, Pageable pageable);

    @Query("SELECT p FROM PostMst p WHERE p.categoryId = :categoryId "
            + "AND p.userId NOT IN :blockedUserIds "
            + "ORDER BY CASE WHEN p.pinnedYn = 'Y' THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<PostMst> findByCategoryOrderedExcluding(@Param("categoryId") Long categoryId,
            @Param("blockedUserIds") Collection<Long> blockedUserIds, Pageable pageable);

    // ── 어린이 게시판 제외 버전 (V12) ────────────────────────────────────────────
    // 전체 피드에서만 쓴다. 카테고리를 콕 집어 들어오는 경로는 KidsBoardPolicy 가 403 으로 막으므로
    // 여기서 또 거를 필요가 없다.
    // ⚠️ 정렬은 위 쿼리들과 한 글자도 다르면 안 된다 (차단 필터와 같은 이유).

    @Query("SELECT p FROM PostMst p WHERE p.categoryId <> :excludeCategoryId "
            + "ORDER BY CASE WHEN p.pinnedYn = 'Y' THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<PostMst> findAllOrderedExcludingCategory(
            @Param("excludeCategoryId") Long excludeCategoryId, Pageable pageable);

    @Query("SELECT p FROM PostMst p WHERE p.categoryId <> :excludeCategoryId "
            + "AND p.userId NOT IN :blockedUserIds "
            + "ORDER BY CASE WHEN p.pinnedYn = 'Y' THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<PostMst> findAllOrderedExcludingCategoryAndUsers(
            @Param("excludeCategoryId") Long excludeCategoryId,
            @Param("blockedUserIds") Collection<Long> blockedUserIds, Pageable pageable);
}
