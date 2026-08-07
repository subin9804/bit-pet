package io.bitpet.nfc.domain;

/**
 * 태그 한 장의 유통 상태 (nfc_tag_mst.status 에 저장된다).
 *
 * <p>응답 전용인 {@link TagStatus} 와 다르다 — 저쪽은 "지금 스캔한 사람 기준" 판정이고,
 * 이쪽은 태그 자체의 생애주기다.
 */
public enum TagStockStatus {
    /** 미판매 재고 */
    STOCK,
    /** 판매됐으나 아직 개체와 연결되지 않음 (온보딩 이탈 의심) */
    SOLD,
    /** 개체에 연결됨 */
    BOUND,
    /** 분실·복제 사고로 영구 차단. 다시 살아나지 않는다 */
    REVOKED
}
