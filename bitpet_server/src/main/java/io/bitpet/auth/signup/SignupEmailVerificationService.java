package io.bitpet.auth.signup;

import io.bitpet.auth.mail.MailSender;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.auth.service.EmailPolicy;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;
import java.util.UUID;

/**
 * 이메일 가입 전 주소 확인 — 코드 발송 → 코드 확인(토큰 발급) → 가입 때 토큰 확인·소비.
 *
 * <p>비밀번호 재설정과 달리 "이미 가입된 주소"를 그대로 알려 준다. 가입 화면은 원래
 * check-email 로 중복 여부를 보여 주므로 숨겨도 얻는 게 없고, 이미 가입한 사람에게
 * 가입 코드 메일을 보내는 쪽이 더 이상하다.
 *
 * <p>자녀 계정({@code GuardianService#createChild})은 대상이 아니다 — 인증된 보호자가 만들고,
 * 아이에게 메일함이 없을 수 있다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SignupEmailVerificationService {

    private final SignupEmailStore store;
    private final SignupProperties properties;
    private final MailSender mailSender;
    private final UserMstRepository userRepository;

    private final SecureRandom random = new SecureRandom();

    public void sendCode(String rawEmail) {
        String email = EmailPolicy.normalize(rawEmail);
        requireAllowedDomain(email);
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_ALREADY_EXISTS);
        }
        // 메일 폭탄 방지 — 같은 주소로 연달아 못 보낸다
        if (!store.tryStartCooldown(email, Duration.ofSeconds(properties.resendCooldownSeconds()))) {
            throw new BusinessException(ErrorCode.SIGNUP_CODE_COOLDOWN);
        }

        String code = String.format("%06d", random.nextInt(1_000_000));
        store.saveCode(email, code, Duration.ofMinutes(properties.codeTtlMinutes()));
        mailSender.sendSignupVerificationCode(email, code);
        log.info("Signup verification code issued: email={}", email);
    }

    /** 코드가 맞으면 가입 요청에 실어 보낼 토큰을 돌려준다 */
    public String verifyCode(String rawEmail, String code) {
        String email = EmailPolicy.normalize(rawEmail);
        String saved = store.getCode(email);
        if (saved == null) {
            throw new BusinessException(ErrorCode.SIGNUP_CODE_NOT_FOUND);
        }
        if (!saved.equals(code)) {
            // 6자리는 100만 가지 — 횟수 제한이 없으면 유효 시간 안에 다 찍어 볼 수 있다
            long failures = store.recordFailure(email, Duration.ofMinutes(properties.codeTtlMinutes()));
            if (failures >= properties.maxAttempts()) {
                store.deleteCode(email);
                throw new BusinessException(ErrorCode.SIGNUP_CODE_TOO_MANY_ATTEMPTS);
            }
            throw new BusinessException(ErrorCode.SIGNUP_CODE_INVALID);
        }

        String token = UUID.randomUUID().toString();
        store.saveVerified(token, email, Duration.ofMinutes(properties.verifiedTtlMinutes()));
        store.deleteCode(email);
        log.info("Signup email verified: email={}", email);
        return token;
    }

    /**
     * 가입 직전 검사. 토큰은 같은 주소로 발급된 것이어야 한다 —
     * A 주소로 인증받고 B 주소로 가입하는 걸 막는다.
     */
    public void requireVerified(String normalizedEmail, String token) {
        requireAllowedDomain(normalizedEmail);
        if (!properties.emailVerificationRequired()) return;
        String verified = token == null || token.isBlank() ? null : store.getVerifiedEmail(token);
        if (verified == null || !verified.equals(normalizedEmail)) {
            throw new BusinessException(ErrorCode.SIGNUP_EMAIL_NOT_VERIFIED);
        }
    }

    /** 가입이 끝나면 토큰을 지워 재사용을 막는다 */
    public void consume(String token) {
        if (token != null && !token.isBlank()) store.deleteVerified(token);
    }

    public boolean isDomainAllowed(String rawEmail) {
        return properties.isDomainAllowed(EmailPolicy.normalize(rawEmail));
    }

    private void requireAllowedDomain(String normalizedEmail) {
        if (!properties.isDomainAllowed(normalizedEmail)) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_DOMAIN_NOT_ALLOWED);
        }
    }
}
