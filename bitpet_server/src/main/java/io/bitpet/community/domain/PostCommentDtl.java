package io.bitpet.community.domain;

import io.bitpet.common.entity.BaseSyncEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.SQLRestriction;

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "post_comment_dtl",
        indexes = {
                @Index(name = "idx_post_comment_dtl_post",   columnList = "post_id, created_at"),
                @Index(name = "idx_post_comment_dtl_parent", columnList = "parent_comment_id")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PostCommentDtl extends BaseSyncEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "post_id", nullable = false)
    private Long postId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "parent_comment_id")
    private Long parentCommentId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private PostCommentDtl(Long postId, Long userId, Long parentCommentId, String content) {
        this.postId          = postId;
        this.userId          = userId;
        this.parentCommentId = parentCommentId;
        this.content         = content;
    }

    public void update(String content) { this.content = content; }

    public void softDelete() { this.deletedAt = Instant.now(); }
}
