package io.bitpet.community.repository;

import io.bitpet.community.domain.PostCommentDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PostCommentDtlRepository extends JpaRepository<PostCommentDtl, Long> {

    List<PostCommentDtl> findAllByPostIdOrderByCreatedAtAsc(Long postId);
}
