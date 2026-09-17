package io.bitpet.community.dto;

import io.bitpet.community.domain.PostReportDtl;

import java.time.Instant;

/**
 * 운영자 큐의 한 건.
 *
 * <p>{@code targetPreview} 는 신고 대상의 본문 앞부분이다 — 운영자가 원문을 열지 않고도
 * 명백한 건을 쳐낼 수 있어야 큐가 밀리지 않는다. 대상이 이미 삭제됐으면 null 이다.
 *
 * <p>{@code reportCount} 는 같은 대상에 쌓인 신고 수. ⛔ 이 수가 크다고 자동 조치하지 말 것 —
 * 여럿이 몰려가면 멀쩡한 글이 사라지는 조리돌림 도구가 된다. 우선순위 신호까지다.
 */
public record ReportResponse(
        Long id,
        String targetType,
        Long targetId,
        Long targetUserId,
        String targetUserNickname,
        String targetPreview,
        boolean targetBlinded,
        String reasonCd,
        String reasonLabel,
        String detail,
        String status,
        String actionTaken,
        Long reporterUserId,
        long reportCount,
        Instant createdAt,
        Instant handledAt,
        String handlerMemo
) {

    public static ReportResponse of(PostReportDtl r, String targetUserNickname,
                                    String targetPreview, boolean targetBlinded, long reportCount) {
        return new ReportResponse(
                r.getId(),
                r.getTargetType().name(),
                r.getTargetId(),
                r.getTargetUserId(),
                targetUserNickname,
                targetPreview,
                targetBlinded,
                r.getReasonCd().name(),
                r.getReasonCd().getLabel(),
                r.getDetail(),
                r.getStatus().name(),
                r.getActionTaken() == null ? null : r.getActionTaken().name(),
                r.getReporterUserId(),
                reportCount,
                r.getCreatedAt(),
                r.getHandledAt(),
                r.getHandlerMemo());
    }
}
