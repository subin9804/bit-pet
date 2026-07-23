package io.bitpet.community.repository;

import io.bitpet.community.domain.PostLikeRls;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface PostLikeRlsRepository extends JpaRepository<PostLikeRls, Long> {

    Optional<PostLikeRls> findByPostIdAndUserId(Long postId, Long userId);

    boolean existsByPostIdAndUserId(Long postId, Long userId);

    // 현재 유저가 좋아요한 게시글 판별용 (목록 배치 조회)
    List<PostLikeRls> findByUserIdAndPostIdIn(Long userId, Collection<Long> postIds);
}
