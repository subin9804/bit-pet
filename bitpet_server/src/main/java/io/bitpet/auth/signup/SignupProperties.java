package io.bitpet.auth.signup;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;
import java.util.Locale;

/**
 * 이메일 가입 규칙 (2026-11-06).
 *
 * <p>전엔 이메일·비밀번호·닉네임만 받아 주소가 진짜인지 확인하지 않았다. 오타 주소로 가입하면
 * 비밀번호 재설정 메일을 못 받고, 아무 주소나 넣어 계정을 찍어낼 수도 있었다.
 *
 * @param allowedEmailDomains       가입을 받는 도메인 (@ 뒤). 비우면 제한 없음
 * @param emailVerificationRequired false 면 인증 토큰 없이 가입된다 — 테스트 전용 스위치
 * @param codeTtlMinutes            인증 코드 유효 시간
 * @param verifiedTtlMinutes        인증 후 가입을 마칠 때까지의 시간
 * @param resendCooldownSeconds     같은 주소로 다시 보내기까지 기다리는 시간
 * @param maxAttempts               코드 하나에 허용하는 오답 횟수
 */
@ConfigurationProperties(prefix = "bitpet.signup")
public record SignupProperties(
        List<String> allowedEmailDomains,
        boolean emailVerificationRequired,
        int codeTtlMinutes,
        int verifiedTtlMinutes,
        int resendCooldownSeconds,
        int maxAttempts
) {
    /** {@code normalizedEmail} 은 EmailPolicy.normalize 를 거친 값 */
    public boolean isDomainAllowed(String normalizedEmail) {
        if (allowedEmailDomains == null || allowedEmailDomains.isEmpty()) return true;
        if (normalizedEmail == null) return false;
        int at = normalizedEmail.lastIndexOf('@');
        if (at < 0) return false;
        String domain = normalizedEmail.substring(at + 1);
        return allowedEmailDomains.stream()
                .anyMatch(d -> d.trim().toLowerCase(Locale.ROOT).equals(domain));
    }
}
