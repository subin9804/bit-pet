package io.bitpet.auth.domain;

/** 동의를 받은 경로. 분쟁 시 "어느 화면에서 받은 동의인가"를 답할 수 있어야 한다. */
public enum AgreementSource {

    /** 이메일 회원가입 3단계 */
    SIGNUP,

    /** 소셜 로그인으로 계정이 처음 만들어진 시점 */
    OAUTH_SIGNUP,

    /** 마이페이지에서 사용자가 직접 변경 (마케팅 수신 토글) */
    SETTINGS,

    /** 약관 개정 후 재동의 */
    REAGREEMENT
}
