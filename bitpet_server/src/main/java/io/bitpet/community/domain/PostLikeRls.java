package io.bitpet.community.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
        name = "post_like_rls",
        indexes = @Index(name = "idx_post_like_rls_user", columnList = "user_id"),
        uniqueConstraints = @UniqueConstraint(name = "uk_post_like_rls", columnNames = {"post_id", "user_id"})
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PostLikeRls extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "post_id", nullable = false)
    private Long postId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Builder
    private PostLikeRls(Long postId, Long userId) {
        this.postId = postId;
        this.userId = userId;
    }
}
