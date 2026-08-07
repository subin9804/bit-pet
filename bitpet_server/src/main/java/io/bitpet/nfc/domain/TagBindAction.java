package io.bitpet.nfc.domain;

/** {@link NfcTagBindHst} 의 액션 종류. DB CHECK 제약(ck_nfc_tag_bind_hst_action)과 값이 일치해야 한다 */
public enum TagBindAction {
    /** 미연결 태그를 개체에 처음 붙였다 */
    BIND,
    /** 이미 다른 개체에 붙어 있던 태그를 옮겼다. prevPetId 가 채워진다 */
    REBIND,
    /** 연결 해제 (사용자 해제 · 개체 삭제 · 탈퇴 정리) */
    UNBIND,
    /** 분실·복제 신고로 영구 차단 */
    REVOKE
}
