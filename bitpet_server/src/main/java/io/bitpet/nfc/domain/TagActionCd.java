package io.bitpet.nfc.domain;

/**
 * 태그를 스캔했을 때 앱이 수행할 기본 동작.
 *
 * <p>제품 라인업(기본형/급여용/체중용)은 이 값으로만 구분한다.
 * 태그에 굽는 URL 은 동일하므로 물리 재고는 한 종류만 유지하면 된다.
 */
public enum TagActionCd {
    /** 개체 상세로 이동만 */
    PET_DETAIL,
    /** 개체 상세 + 급여 기록 시트 자동 오픈 */
    RECORD_FEEDING,
    /** 개체 상세 + 체중 기록 시트 자동 오픈 */
    RECORD_WEIGHT
}
