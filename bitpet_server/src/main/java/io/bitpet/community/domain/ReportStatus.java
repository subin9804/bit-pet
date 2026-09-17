package io.bitpet.community.domain;

/** 신고 처리 상태. PENDING 이 아닌 행에는 처리자·처리 시각이 반드시 있다 (DB CHECK). */
public enum ReportStatus {
    /** 접수됨 — 운영자 큐에 남아 있다 */
    PENDING,
    /** 위반으로 보고 조치함 */
    RESOLVED,
    /** 검토했으나 위반이 아님 */
    REJECTED
}
