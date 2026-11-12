package io.bitpet.auth.domain;

import java.time.LocalDate;
import java.time.Period;
import java.time.ZoneId;

/**
 * 가입 연령 확인 (2026-11-13).
 *
 * <p>"만 14세 이상입니다" 체크박스는 기준선을 대놓고 알려줘서 아이가 그냥 체크하고 넘어갔다.
 * 그래서 앱은 기준을 말하지 않고 생년월일만 묻고, 서버가 여기서 판정한다.
 * 생년월일은 판정에만 쓰고 저장하지 않는다 — 처리방침에 없는 항목을 새로 모으지 않으려는 것.
 * 만 14세 미만은 보호자 계정의 자녀 계정(GuardianService)으로만 들어온다.
 */
public final class AgePolicy {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");
    /** 이보다 이른 날짜는 입력 실수로 본다 */
    private static final LocalDate OLDEST = LocalDate.of(1900, 1, 1);

    private AgePolicy() {}

    public static LocalDate today() {
        return LocalDate.now(SEOUL);
    }

    public static boolean isUnderConsentAge(LocalDate birthDate, LocalDate baseDate) {
        return Period.between(birthDate, baseDate).getYears() < UserMst.GUARDIAN_CONSENT_AGE;
    }

    /** 있을 수 없는 날짜(미래·1900년 이전)인가 */
    public static boolean isImplausible(LocalDate birthDate, LocalDate baseDate) {
        return birthDate.isAfter(baseDate) || birthDate.isBefore(OLDEST);
    }
}
