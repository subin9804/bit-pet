package io.bitpet.community.repository;

import io.bitpet.community.domain.PostMst;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface PostMstRepository extends JpaRepository<PostMst, Long> {

    // ── 피드: 커서(마지막으로 본 글 id) 기반 (2026-11-17) ───────────────────────
    // 예전엔 page 번호(offset)로 끊었다. 스크롤 중에 새 글이 올라오면 전체가 한 칸씩 밀려
    // 다음 페이지 첫 글이 방금 본 글과 겹쳤다(지워지면 반대로 한 건을 건너뛴다).
    // "이 id 보다 오래된 N개" 로 물으면 앞쪽에서 무슨 일이 일어나도 이어지는 지점이 고정된다.
    //
    // - 순서는 id DESC. id 는 시퀀스라 작성 순서와 같고 유일하다 — created_at 은 같은 값이
    //   나올 수 있어 커서로 쓰면 경계에서 글이 빠진다.
    // - 고정 글은 따로 읽어 **첫 요청에만** 맨 위에 붙인다. 정렬에 섞으면 커서가 두 축이 된다.
    // - 차단·어린이 게시판 제외는 **센티널(-1)** 로 항상 걸어 쿼리를 한 벌로 줄였다.
    //   JPQL `NOT IN (:list)` 는 빈 리스트에서 터지므로 부르는 쪽이 비어 있으면 [-1] 을 넘긴다.
    //   예전처럼 "차단 유무에 따라 다른 쿼리" 로 나누지 않으니 정렬이 갈라질 일도 없다.

    @Query("SELECT p FROM PostMst p WHERE p.pinnedYn = 'Y' "
            + "AND p.categoryId <> :excludeCategoryId AND p.userId NOT IN :hiddenUserIds "
            + "ORDER BY p.id DESC")
    List<PostMst> findPinned(@Param("excludeCategoryId") Long excludeCategoryId,
                             @Param("hiddenUserIds") Collection<Long> hiddenUserIds);

    @Query("SELECT p FROM PostMst p WHERE p.pinnedYn = 'Y' AND p.categoryId = :categoryId "
            + "AND p.userId NOT IN :hiddenUserIds "
            + "ORDER BY p.id DESC")
    List<PostMst> findPinnedInCategory(@Param("categoryId") Long categoryId,
                                       @Param("hiddenUserIds") Collection<Long> hiddenUserIds);

    /** {@code pageable} 은 크기만 쓴다 (항상 0페이지). 하나 더 읽어 다음이 있는지 판단한다. */
    @Query("SELECT p FROM PostMst p WHERE p.pinnedYn = 'N' AND p.id < :cursor "
            + "AND p.categoryId <> :excludeCategoryId AND p.userId NOT IN :hiddenUserIds "
            + "ORDER BY p.id DESC")
    List<PostMst> findFeedBefore(@Param("cursor") Long cursor,
                                 @Param("excludeCategoryId") Long excludeCategoryId,
                                 @Param("hiddenUserIds") Collection<Long> hiddenUserIds,
                                 Pageable pageable);

    @Query("SELECT p FROM PostMst p WHERE p.pinnedYn = 'N' AND p.id < :cursor "
            + "AND p.categoryId = :categoryId AND p.userId NOT IN :hiddenUserIds "
            + "ORDER BY p.id DESC")
    List<PostMst> findFeedInCategoryBefore(@Param("cursor") Long cursor,
                                           @Param("categoryId") Long categoryId,
                                           @Param("hiddenUserIds") Collection<Long> hiddenUserIds,
                                           Pageable pageable);

    Page<PostMst> findByUserId(Long userId, Pageable pageable);
}
