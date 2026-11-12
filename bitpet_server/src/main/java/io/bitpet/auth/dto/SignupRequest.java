package io.bitpet.auth.dto;

import io.bitpet.auth.domain.AgePolicy;
import io.bitpet.common.validation.ValidPassword;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record SignupRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(max = 64) @ValidPassword String password,
        // 상세 규칙(허용 문자·예약어)은 NicknamePolicy 가 본다. 여기 길이는 그와 맞춘 1차 방어선.
        @NotBlank @Size(min = 2, max = 20) String nickname,

        // 프로필 색 팔레트 키. 안 보내면 기본값('peach')이 붙는다 —
        // 색은 가입을 막을 만한 정보가 아니라서 필수로 두지 않는다.
        @Size(max = 20) String profileColor,

        // 약관 동의. 필수 3종은 true 가 아니면 400 이다.
        // Boolean(래퍼)인 이유 — boolean 이면 필드가 통째로 빠진 요청이 false 로 조용히
        // 통과해 "동의하지 않음"으로 기록된다. null 과 false 는 구별해야 한다.
        @NotNull Boolean agreeTos,
        @NotNull Boolean agreePrivacy,
        // 연령 확인 — 생년월일을 받으면 그걸로 판정하고 agreeAge 는 보지 않는다 (2026-11-13).
        // 앱은 기준 나이를 말하지 않고 생년월일만 묻는다. agreeAge 는 구버전 앱 호환용.
        // 생년월일은 판정에만 쓰고 저장하지 않는다 (AgePolicy).
        Boolean agreeAge,
        LocalDate birthDate,
        // 선택 항목. 안 보내면 미동의로 본다.
        Boolean agreeMarketing,

        // 이메일 인증 결과 토큰 (POST /auth/signup/email-code/verify). 필수 여부는 서버 설정이
        // 정한다 — 여기서 @NotBlank 를 걸면 테스트가 가입마다 인증을 거쳐야 한다.
        @Size(max = 64) String emailVerificationToken
) {
    @AssertTrue(message = "서비스 이용약관에 동의해야 가입할 수 있습니다")
    public boolean isTosAgreed() {
        return Boolean.TRUE.equals(agreeTos);
    }

    @AssertTrue(message = "개인정보 처리방침에 동의해야 가입할 수 있습니다")
    public boolean isPrivacyAgreed() {
        return Boolean.TRUE.equals(agreePrivacy);
    }

    @AssertTrue(message = "생년월일을 다시 확인해 주세요")
    public boolean isBirthDatePlausible() {
        return birthDate == null || !AgePolicy.isImplausible(birthDate, AgePolicy.today());
    }

    @AssertTrue(message = "만 14세 미만은 보호자가 자녀 계정을 만들어 주세요")
    public boolean isAgeAgreed() {
        if (birthDate != null) return !AgePolicy.isUnderConsentAge(birthDate, AgePolicy.today());
        return Boolean.TRUE.equals(agreeAge);
    }

    public boolean marketingAgreed() {
        return Boolean.TRUE.equals(agreeMarketing);
    }
}
