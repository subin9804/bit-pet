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

    /** 운영자가 가린 시각. 내용은 남기고 응답에서만 치환한다 (작성자 삭제는 {@code deletedAt}) */
    @Column(name = "blinded_at")
    private Instant blindedAt;

    @Column(name = "blinded_by")
    private Long blindedBy;

    @Builder
    private PostCommentDtl(Long postId, Long userId, Long parentCommentId, String content) {
        this.postId          = postId;
        this.userId          = userId;
        this.parentCommentId = parentCommentId;
        this.content         = content;
    }

    public void update(String content) { this.content = content; }

    public void softDelete() { this.deletedAt = Instant.now(); }

    public boolean isBlinded() { return this.blindedAt != null; }

    /** 운영자 블라인드 설정·해제. 해제하면 원문이 그대로 다시 보인다 */
    public void setBlinded(boolean blinded, Long adminUserId) {
        this.blindedAt = blinded ? Instant.now() : null;
        this.blindedBy = blinded ? adminUserId : null;
    }
}
