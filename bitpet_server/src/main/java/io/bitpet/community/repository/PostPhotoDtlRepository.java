package io.bitpet.community.repository;

import io.bitpet.community.domain.PostPhotoDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface PostPhotoDtlRepository extends JpaRepository<PostPhotoDtl, Long> {

    List<PostPhotoDtl> findAllByPostIdOrderByDisplayOrderAsc(Long postId);

    /** 목록 썸네일용 — 게시글마다 따로 부르면 N+1 이라 한 번에 읽는다. */
    List<PostPhotoDtl> findAllByPostIdInOrderByPostIdAscDisplayOrderAsc(Collection<Long> postIds);

    int countByPostId(Long postId);
}
