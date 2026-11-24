package io.bitpet.community.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * 커뮤니티 이용 정지 (V5). 신고 처리의 SUSPEND 조치가 만든다.
 *
 * <p>정지 상태는 저장하지 않고 이 행에서 계산한다 — 기간이 지나면 배치 없이 저절로 풀린다.
 */
@Entity
@Getter
@Table(name = "user_suspension_dtl")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserSuspensionDtl extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "report_id")
    private Long reportId;

    @Column(length = 500)
    private String reason;

    /** null = 영구 */
    @Column(name = "ends_at")
    private Instant endsAt;

    @Column(name = "created_by", nullable = false)
    private Long createdBy;

    @Column(name = "released_at")
    private Instant releasedAt;

    @Column(name = "released_by")
    private Long releasedBy;

    @Builder
    private UserSuspensionDtl(Long userId, Long reportId, String reason, Instant endsAt, Long createdBy) {
        this.userId = userId;
        this.reportId = reportId;
        this.reason = reason;
        this.endsAt = endsAt;
        this.createdBy = createdBy;
    }

    public boolean isPermanent() {
        return endsAt == null;
    }

    public boolean isActiveAt(Instant now) {
        return releasedAt == null && (endsAt == null || endsAt.isAfter(now));
    }

    /** 운영자가 기간 전에 푼다. 이미 끝난 정지는 그대로 둔다(이력이 거짓이 된다). */
    public void release(Long adminUserId) {
        if (!isActiveAt(Instant.now())) return;
        this.releasedAt = Instant.now();
        this.releasedBy = adminUserId;
    }
}
