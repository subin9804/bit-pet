package io.bitpet.auth.dto;

import io.bitpet.common.validation.ValidPassword;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record SignupRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(max = 64) @ValidPassword String password,
        // 상세 규칙(허용 문자·예약어)은 NicknamePolicy 가 본다. 여기 길이는 그와 맞춘 1차 방어선.
        @NotBlank @Size(min = 2, max = 20) String nickname,

        // 약관 동의. 필수 3종은 true 가 아니면 400 이다.
        // Boolean(래퍼)인 이유 — boolean 이면 필드가 통째로 빠진 요청이 false 로 조용히
        // 통과해 "동의하지 않음"으로 기록된다. null 과 false 는 구별해야 한다.
        @NotNull Boolean agreeTos,
        @NotNull Boolean agreePrivacy,
        @NotNull Boolean agreeAge,
        // 선택 항목. 안 보내면 미동의로 본다.
        Boolean agreeMarketing
) {
    @AssertTrue(message = "서비스 이용약관에 동의해야 가입할 수 있습니다")
    public boolean isTosAgreed() {
        return Boolean.TRUE.equals(agreeTos);
    }

    @AssertTrue(message = "개인정보 처리방침에 동의해야 가입할 수 있습니다")
    public boolean isPrivacyAgreed() {
        return Boolean.TRUE.equals(agreePrivacy);
    }

    @AssertTrue(message = "만 14세 이상만 가입할 수 있습니다")
    public boolean isAgeAgreed() {
        return Boolean.TRUE.equals(agreeAge);
    }

    public boolean marketingAgreed() {
        return Boolean.TRUE.equals(agreeMarketing);
    }
}
