package io.bitpet.community.repository;

import io.bitpet.community.domain.PostLikeRls;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PostLikeRlsRepository extends JpaRepository<PostLikeRls, Long> {

    Optional<PostLikeRls> findByPostIdAndUserId(Long postId, Long userId);

    boolean existsByPostIdAndUserId(Long postId, Long userId);
}
