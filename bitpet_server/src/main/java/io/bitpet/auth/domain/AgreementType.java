package io.bitpet.auth.domain;

/**
 * 동의 항목.
 *
 * <p>{@code version} 은 앱의 {@code lib/core/legal/legal_documents.dart} 의 시행일과
 * 반드시 같아야 한다. 약관 본문을 고치면서 여기 버전을 안 올리면, 바뀐 내용에 대해
 * 동의를 받은 적이 없는데 받은 것처럼 기록이 남는다 — 기록이 없느니만 못한 상태가 된다.
 */
public enum AgreementType {

    /** 서비스 이용약관 (필수) */
    TOS("2026-08-19", true),

    /** 개인정보 처리방침 (필수) */
    PRIVACY("2026-08-19", true),

    /** 만 14세 이상 확인 (필수) */
    AGE_14("2026-08-19", true),

    /** 마케팅 정보 수신 (선택) */
    MARKETING("2026-08-19", false);

    private final String currentVersion;
    private final boolean required;

    AgreementType(String currentVersion, boolean required) {
        this.currentVersion = currentVersion;
        this.required = required;
    }

    public String currentVersion() {
        return currentVersion;
    }

    /** 필수 항목은 동의하지 않으면 가입 자체가 불가능하다. */
    public boolean isRequired() {
        return required;
    }
}
