package io.bitpet.community.repository;

import io.bitpet.community.domain.PostMst;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PostMstRepository extends JpaRepository<PostMst, Long> {

    Page<PostMst> findByCategoryId(Long categoryId, Pageable pageable);

    Page<PostMst> findAllBy(Pageable pageable);

    Page<PostMst> findByUserId(Long userId, Pageable pageable);
}
