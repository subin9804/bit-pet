package io.bitpet.community.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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

import java.time.Instant;

/**
 * 커뮤니티 신고.
 *
 * <p>접수되면 신고자 → 작성자 <b>차단이 함께 생성된다</b>. 신고했는데 그 글이 계속 보이면
 * 신고한 의미가 없기 때문이다. 반대로 차단은 신고를 만들지 않는다.
 *
 * <p><b>신고는 취소되지 않는다.</b> 접수된 사건의 이력이라 지우면 "몇 번 신고당했는지" 가
 * 사라진다. 마음이 바뀐 사용자는 차단만 해제하면 된다.
 *
 * <p>⛔ 누적 신고 수로 자동 블라인드하지 말 것. 여럿이 몰려가 신고하면 멀쩡한 글이 사라지는
 * 조리돌림 도구가 된다. 누적은 운영자에게 알리는 신호까지만이다.
 */
@Entity
@Getter
@Table(
        name = "post_report_dtl",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_post_report_dtl",
                        columnNames = {"reporter_user_id", "target_type", "target_id"})
        },
        indexes = {
                @Index(name = "idx_post_report_dtl_queue",  columnList = "status, created_at"),
                @Index(name = "idx_post_report_dtl_target", columnList = "target_type, target_id")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PostReportDtl extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "reporter_user_id", nullable = false)
    private Long reporterUserId;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_type", nullable = false, length = 10)
    private ReportTargetType targetType;

    @Column(name = "target_id", nullable = false)
    private Long targetId;

    /**
     * 신고당한 글·댓글의 작성자.
     *
     * <p>대상 글을 타고 들어가면 알 수 있지만 <b>비정규화해서 들고 있는다</b> —
     * 글이 지워지고 나서도 누구를 신고한 것인지는 남아야 운영자가 판단할 수 있다.
     */
    @Column(name = "target_user_id", nullable = false)
    private Long targetUserId;

    @Enumerated(EnumType.STRING)
    @Column(name = "reason_cd", nullable = false, length = 20)
    private ReportReason reasonCd;

    @Column(columnDefinition = "TEXT")
    private String detail;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private ReportStatus status;

    @Enumerated(EnumType.STRING)
    @Column(name = "action_taken", length = 20)
    private ReportAction actionTaken;

    @Column(name = "handled_by")
    private Long handledBy;

    @Column(name = "handled_at")
    private Instant handledAt;

    @Column(name = "handler_memo", columnDefinition = "TEXT")
    private String handlerMemo;

    @Builder
    private PostReportDtl(Long reporterUserId, ReportTargetType targetType, Long targetId,
                          Long targetUserId, ReportReason reasonCd, String detail) {
        this.reporterUserId = reporterUserId;
        this.targetType     = targetType;
        this.targetId       = targetId;
        this.targetUserId   = targetUserId;
        this.reasonCd       = reasonCd;
        this.detail         = detail;
        this.status         = ReportStatus.PENDING;
    }

    /** 운영자 처리. 처리자·시각이 함께 박히지 않으면 DB CHECK 가 거부한다 */
    public void handle(ReportStatus status, ReportAction action, Long handlerUserId, String memo) {
        if (status == ReportStatus.PENDING) {
            throw new IllegalArgumentException("처리 결과는 PENDING 일 수 없습니다");
        }
        this.status      = status;
        this.actionTaken = action;
        this.handledBy   = handlerUserId;
        this.handledAt   = Instant.now();
        this.handlerMemo = memo;
    }
}
