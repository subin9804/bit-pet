package io.bitpet.nfc.domain;

/**
 * 태그 조회 결과 상태. 앱은 이 값만 보고 분기한다.
 * (엔티티에 저장되지 않는 응답 전용 값)
 */
public enum TagStatus {
    /** 아직 어떤 개체와도 연결되지 않음 → 개체 선택 모달 */
    UNLINKED,
    /** 내 개체와 연결됨 → 개체 상세 + 기본 동작 */
    LINKED,
    /** 남의 개체와 연결됨 → 안내만 */
    OWNED_BY_OTHER
}
