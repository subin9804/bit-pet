package io.bitpet.community.repository;

import io.bitpet.community.domain.PostPhotoDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PostPhotoDtlRepository extends JpaRepository<PostPhotoDtl, Long> {

    List<PostPhotoDtl> findAllByPostIdOrderByDisplayOrderAsc(Long postId);

    int countByPostId(Long postId);
}
