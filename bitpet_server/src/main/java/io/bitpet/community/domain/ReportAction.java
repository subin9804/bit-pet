package io.bitpet.community.domain;

/** 운영자가 신고에 대해 취한 조치. */
public enum ReportAction {
    /** 위반 아님 — 아무것도 하지 않음 */
    NONE,
    /** 가림. 내용은 남기고 응답에서만 치환한다 (작성자 삭제와 구분) */
    BLIND,
    /** 삭제 */
    DELETE,
    /** 작성자 계정 정지 */
    SUSPEND
}
