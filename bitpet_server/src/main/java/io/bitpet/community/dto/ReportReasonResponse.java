package io.bitpet.community.dto;

import io.bitpet.community.domain.ReportReason;

/**
 * 신고 사유 선택지.
 *
 * <p>앱이 라벨을 직접 들고 있지 않고 서버에서 받는다 — 사유가 늘거나 문구가 바뀔 때
 * 앱 스토어 심사를 기다리지 않아도 되게.
 */
public record ReportReasonResponse(String code, String label) {

    public static ReportReasonResponse from(ReportReason reason) {
        return new ReportReasonResponse(reason.name(), reason.getLabel());
    }
}
