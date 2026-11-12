package io.bitpet.auth.dto;

import io.bitpet.auth.domain.AgePolicy;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

/** 소셜 가입 직후 동의, 또는 약관 개정 후 재동의. */
public record AgreementAcceptRequest(
        @NotNull Boolean agreeTos,
        @NotNull Boolean agreePrivacy,
        // 연령 확인 — 생년월일을 받으면 그걸로 판정하고 agreeAge 는 보지 않는다.
        // agreeAge 는 생년월일을 안 보내는 구버전 앱과 재동의(이미 연령 확인을 마친 계정)용으로 남긴다.
        // 생년월일은 판정에만 쓰고 저장하지 않는다 (AgePolicy).
        Boolean agreeAge,
        LocalDate birthDate,
        Boolean agreeMarketing
) {
    @AssertTrue(message = "필수 약관에 모두 동의해야 합니다")
    public boolean isRequiredAgreed() {
        return Boolean.TRUE.equals(agreeTos) && Boolean.TRUE.equals(agreePrivacy);
    }

    @AssertTrue(message = "생년월일을 다시 확인해 주세요")
    public boolean isBirthDatePlausible() {
        return birthDate == null || !AgePolicy.isImplausible(birthDate, AgePolicy.today());
    }

    @AssertTrue(message = "만 14세 미만은 보호자가 자녀 계정을 만들어 주세요")
    public boolean isAgeConfirmed() {
        if (birthDate != null) return !AgePolicy.isUnderConsentAge(birthDate, AgePolicy.today());
        return Boolean.TRUE.equals(agreeAge);
    }

    public boolean marketingAgreed() {
        return Boolean.TRUE.equals(agreeMarketing);
    }
}
