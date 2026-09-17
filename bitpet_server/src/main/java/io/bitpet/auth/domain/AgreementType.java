package io.bitpet.auth.domain;

import java.util.Arrays;
import java.util.List;

/**
 * 동의 항목.
 *
 * <p>{@code version} 은 앱의 {@code lib/core/legal/legal_documents.dart} 의 시행일과
 * 반드시 같아야 한다. 약관 본문을 고치면서 여기 버전을 안 올리면, 바뀐 내용에 대해
 * 동의를 받은 적이 없는데 받은 것처럼 기록이 남는다 — 기록이 없느니만 못한 상태가 된다.
 */
public enum AgreementType {

    /** 서비스 이용약관 (필수) */
    TOS("2026-08-19", true, Scope.ALL),

    /** 개인정보 처리방침 (필수) */
    PRIVACY("2026-08-19", true, Scope.ALL),

    /**
     * 만 14세 이상 확인 (필수).
     *
     * <p>자녀 계정에는 해당되지 않는다 — 만 14세 미만임을 전제로 만든 계정이라
     * 여기에 '만 14세 이상이다'라는 동의를 남기면 기록 자체가 거짓이 된다.
     * 그 자리를 {@link #GUARDIAN} 이 대신한다.
     */
    AGE_14("2026-09-17", true, Scope.ADULT_ONLY),

    /** 마케팅 정보 수신 (선택) */
    MARKETING("2026-08-19", false, Scope.ALL),

    /**
     * 법정대리인 동의 (필수, 자녀 계정만).
     *
     * <p>이 행의 {@code user_id} 는 <b>동의의 대상인 자녀</b>다. 누가 눌렀는지는 자녀의
     * {@code guardian_user_id} 를 따라가면 나온다 — 동의 기록은 "누구의 개인정보 처리에
     * 대한 근거인가"로 찾게 되기 때문이다.
     *
     * <p>{@link #isRequired()} 가 true 지만 <b>모든 사용자에게 필요한 것은 아니다</b> —
     * {@link Scope#CHILD_ONLY} 라서 {@link #forSignup()} 에서 빠진다. 일반 가입 흐름에 끼워 넣으면
     * 보호자가 없는 성인 계정이 전부 "필수 약관 미동의"로 가입에 실패한다.
     */
    GUARDIAN("2026-09-17", true, Scope.CHILD_ONLY);

    /** 이 항목이 누구에게 해당하는가 */
    public enum Scope { ALL, ADULT_ONLY, CHILD_ONLY }

    private final String currentVersion;
    private final boolean required;
    private final Scope scope;

    AgreementType(String currentVersion, boolean required, Scope scope) {
        this.currentVersion = currentVersion;
        this.required = required;
        this.scope = scope;
    }

    public Scope scope() {
        return scope;
    }

    /**
     * 일반 가입·재동의 화면이 다루는 항목.
     *
     * <p>⚠️ 새 항목을 추가할 때 {@code values()} 를 그대로 순회하는 코드를 만들지 말 것 —
     * 일부에게만 해당하는 항목이 모두에게 필수로 걸린다.
     */
    public static List<AgreementType> forSignup() {
        return Arrays.stream(values()).filter(t -> t.scope != Scope.CHILD_ONLY).toList();
    }

    /**
     * 자녀 계정 생성 화면이 다루는 항목. {@link #AGE_14} 가 빠지고 {@link #GUARDIAN} 이 들어온다.
     */
    public static List<AgreementType> forChildSignup() {
        return Arrays.stream(values()).filter(t -> t.scope != Scope.ADULT_ONLY).toList();
    }

    public String currentVersion() {
        return currentVersion;
    }

    /** 필수 항목은 동의하지 않으면 가입 자체가 불가능하다. */
    public boolean isRequired() {
        return required;
    }
}
