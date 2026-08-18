package io.bitpet.community.repository;

import io.bitpet.community.domain.PostCommentDtl;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PostCommentDtlRepository extends JpaRepository<PostCommentDtl, Long> {

    List<PostCommentDtl> findAllByPostIdOrderByCreatedAtAsc(Long postId);

    // 마이페이지 '내 댓글'. @SQLRestriction 덕에 소프트 삭제된 내 댓글은 빠진다.
    Page<PostCommentDtl> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);
}
