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
        name = "post_mst",
        indexes = {
                @Index(name = "idx_post_mst_category_time", columnList = "category_id, created_at DESC"),
                @Index(name = "idx_post_mst_user_time",     columnList = "user_id, created_at DESC")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PostMst extends BaseSyncEntity {

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

    /** 공지 상단 고정 여부 Y/N (관리자만 설정) */
    @Column(name = "pinned_yn", nullable = false, length = 1)
    private String pinnedYn = "N";

    @Column(name = "deleted_at")
    private Instant deletedAt;

    /**
     * 운영자가 가린 시각.
     *
     * <p>⛔ {@code deletedAt} 과 합치지 말 것. 삭제는 작성자가 한 일이고 블라인드는 운영자가 한 일이라
     * 분쟁이 나면 원문이 남아 있어야 한다. 그래서 내용은 지우지 않고 <b>응답에서만 치환</b>하며,
     * {@code @SQLRestriction} 도 {@code deleted_at} 만 보므로 조회 자체는 계속 된다.
     */
    @Column(name = "blinded_at")
    private Instant blindedAt;

    @Column(name = "blinded_by")
    private Long blindedBy;

    @Builder
    private PostMst(Long userId, Long categoryId, String title, String content) {
        this.userId     = userId;
        this.categoryId = categoryId;
        this.title      = title;
        this.content    = content;
        this.pinnedYn   = "N";
    }

    public boolean isPinned() { return "Y".equals(this.pinnedYn); }

    public void setPinned(boolean pinned) { this.pinnedYn = pinned ? "Y" : "N"; }

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

    public boolean isBlinded() { return this.blindedAt != null; }

    /** 운영자 블라인드 설정·해제. 해제하면 원문이 그대로 다시 보인다 */
    public void setBlinded(boolean blinded, Long adminUserId) {
        this.blindedAt = blinded ? Instant.now() : null;
        this.blindedBy = blinded ? adminUserId : null;
    }
}
