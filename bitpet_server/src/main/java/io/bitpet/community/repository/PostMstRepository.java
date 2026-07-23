package io.bitpet.community.repository;

import io.bitpet.community.domain.PostMst;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PostMstRepository extends JpaRepository<PostMst, Long> {

    // 공지(pinned) 우선, 그다음 최신순. Pageable 의 sort 는 무시하고 page/size 만 사용한다.
    @Query("SELECT p FROM PostMst p "
            + "ORDER BY CASE WHEN p.pinnedYn = 'Y' THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<PostMst> findAllOrdered(Pageable pageable);

    @Query("SELECT p FROM PostMst p WHERE p.categoryId = :categoryId "
            + "ORDER BY CASE WHEN p.pinnedYn = 'Y' THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<PostMst> findByCategoryOrdered(@Param("categoryId") Long categoryId, Pageable pageable);

    Page<PostMst> findByUserId(Long userId, Pageable pageable);
}
