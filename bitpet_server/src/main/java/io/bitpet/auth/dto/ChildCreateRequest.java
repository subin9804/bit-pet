package io.bitpet.auth.dto;

import io.bitpet.common.validation.ValidPassword;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

/**
 * 자녀 계정 생성 요청 (V12). <b>보호자가 로그인한 상태에서</b> 보낸다.
 *
 * <p>여기에 {@code agreeTos}·{@code agreePrivacy} 가 따로 없는 이유 — 자녀 계정의 약관 동의
 * 주체는 법정대리인이고, 그 사실을 한 항목({@code agreeGuardian})으로 받는다. 필수 약관을
 * 아이 이름으로 체크받는 화면을 만들면 "누가 동의했는가"가 기록에서 흐려진다.
 */
public record ChildCreateRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(max = 64) @ValidPassword String password,
        @NotBlank @Size(min = 2, max = 20) String nickname,
        @Size(max = 20) String profileColor,

        /**
         * 자녀의 생년월일. 만 14세 미만이어야 한다 —
         * 만 14세 이상이면 보호자 동의가 필요 없으니 본인이 직접 가입하면 된다.
         */
        @NotNull @Past LocalDate birthDate,

        /**
         * 법정대리인 동의. Boolean 래퍼인 이유는 {@link SignupRequest} 와 같다 —
         * 필드가 빠진 요청이 false 로 조용히 통과해 "동의하지 않음"으로 기록되면 안 된다.
         */
        @NotNull Boolean agreeGuardian,

        /** 자녀 계정의 마케팅 수신. 안 보내면 미동의. */
        Boolean agreeMarketing
) {
    @AssertTrue(message = "법정대리인 동의가 있어야 자녀 계정을 만들 수 있습니다")
    public boolean isGuardianAgreed() {
        return Boolean.TRUE.equals(agreeGuardian);
    }

    public boolean marketingAgreed() {
        return Boolean.TRUE.equals(agreeMarketing);
    }
}
