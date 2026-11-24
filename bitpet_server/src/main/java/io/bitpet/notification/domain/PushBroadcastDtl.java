package io.bitpet.notification.domain;

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

/** 운영자 전체 푸시 한 번 = 한 행 (V5). 받는 사람별 기록은 notification_log_dtl 에 쌓인다. */
@Entity
@Getter
@Table(name = "push_broadcast_dtl")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PushBroadcastDtl extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 운영자가 입력한 그대로 — 마케팅이면 실제 발송 제목엔 (광고) 가 붙는다 */
    @Column(nullable = false, length = 100)
    private String title;

    @Column(nullable = false, length = 500)
    private String body;

    @Column(name = "marketing_yn", nullable = false, length = 1)
    private String marketingYn;

    @Column(name = "target_count", nullable = false)
    private int targetCount;

    @Column(name = "created_by", nullable = false)
    private Long createdBy;

    @Builder
    private PushBroadcastDtl(String title, String body, boolean marketing, int targetCount, Long createdBy) {
        this.title = title;
        this.body = body;
        this.marketingYn = marketing ? "Y" : "N";
        this.targetCount = targetCount;
        this.createdBy = createdBy;
    }

    public boolean isMarketing() {
        return "Y".equals(marketingYn);
    }
}
