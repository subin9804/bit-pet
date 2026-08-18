package io.bitpet.auth.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotNull;

/** 소셜 가입 직후 동의, 또는 약관 개정 후 재동의. */
public record AgreementAcceptRequest(
        @NotNull Boolean agreeTos,
        @NotNull Boolean agreePrivacy,
        @NotNull Boolean agreeAge,
        Boolean agreeMarketing
) {
    @AssertTrue(message = "필수 약관에 모두 동의해야 합니다")
    public boolean isRequiredAgreed() {
        return Boolean.TRUE.equals(agreeTos)
                && Boolean.TRUE.equals(agreePrivacy)
                && Boolean.TRUE.equals(agreeAge);
    }

    public boolean marketingAgreed() {
        return Boolean.TRUE.equals(agreeMarketing);
    }
}
