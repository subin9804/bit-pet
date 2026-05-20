package io.bitpet.community.domain;

import io.bitpet.common.entity.BaseTimeEntity;
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
        name = "post_mst",
        indexes = {
                @Index(name = "idx_post_mst_category_time", columnList = "category_id, created_at DESC"),
                @Index(name = "idx_post_mst_user_time",     columnList = "user_id, created_at DESC")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PostMst extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "category_id", nullable = false)
    private Long categoryId;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "view_count", nullable = false)
    private int viewCount;

    @Column(name = "like_count", nullable = false)
    private int likeCount;

    @Column(name = "comment_count", nullable = false)
    private int commentCount;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private PostMst(Long userId, Long categoryId, String title, String content) {
        this.userId     = userId;
        this.categoryId = categoryId;
        this.title      = title;
        this.content    = content;
    }

    public void update(Long categoryId, String title, String content) {
        this.categoryId = categoryId;
        this.title      = title;
        this.content    = content;
    }

    public void incrementViewCount()    { this.viewCount++; }
    public void incrementLikeCount()    { this.likeCount++; }
    public void decrementLikeCount()    { if (this.likeCount > 0) this.likeCount--; }
    public void incrementCommentCount() { this.commentCount++; }
    public void decrementCommentCount() { if (this.commentCount > 0) this.commentCount--; }

    public void softDelete() { this.deletedAt = Instant.now(); }
}
