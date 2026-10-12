package io.bitpet.record.laying.domain;

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
import java.time.LocalDate;

/**
 * 클러치의 날짜별 관찰 메모.
 *
 * <p>laying_dtl.memo 는 클러치당 한 칸이라 날짜를 쌓을 수 없고, laying_hatch_dtl.memo 는
 * 알 단위라 "인큐 온도를 올렸다" 같은 클러치 전체 관찰과 맞지 않아 따로 뗀 테이블이다.
 * 날짜는 <b>시각이 아니라 날</b>이며, 같은 날 여러 줄을 허용한다.
 */
@Entity
@Getter
@Table(
        name = "laying_note_dtl",
        indexes = @Index(name = "idx_laying_note_laying_date", columnList = "laying_id, noted_at")
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class LayingNoteDtl extends BaseSyncEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "laying_id", nullable = false)
    private Long layingId;

    @Column(name = "noted_at", nullable = false)
    private LocalDate notedAt;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "created_by_user_id")
    private Long createdByUserId;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private LayingNoteDtl(Long layingId, LocalDate notedAt, String content, Long createdByUserId) {
        this.layingId = layingId;
        this.notedAt = notedAt;
        this.content = content;
        this.createdByUserId = createdByUserId;
    }

    public void update(LocalDate notedAt, String content) {
        if (notedAt != null) this.notedAt = notedAt;
        if (content != null) this.content = content;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
