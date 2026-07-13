package io.bitpet.auth.service;

import io.bitpet.auth.PasswordResetStore;
import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.jwt.RefreshTokenStore;
import io.bitpet.auth.mail.MailSender;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private final UserMstRepository userRepository;
    private final PasswordResetStore passwordResetStore;
    private final RefreshTokenStore refreshTokenStore;
    private final MailSender mailSender;
    private final PasswordEncoder passwordEncoder;

    private final SecureRandom random = new SecureRandom();

    /**
     * 1단계 — 인증 코드 발송.
     * 가입되지 않은 이메일이어도 정상 응답한다 (이메일 존재 여부 노출 방지).
     */
    public void requestReset(String email) {
        if (!userRepository.existsByEmail(email)) {
            log.info("Password reset requested for unknown email: {}", email);
            return;
        }

        String code = String.format("%06d", random.nextInt(1_000_000));
        passwordResetStore.saveCode(email, code);
        mailSender.sendPasswordResetCode(email, code);
        log.info("Password reset code issued: email={}", email);
    }

    /**
     * 2단계 — 코드 검증. 성공 시 비밀번호 변경용 검증 토큰을 발급한다.
     */
    public String verifyCode(String email, String code) {
        String savedCode = passwordResetStore.getCode(email);
        if (savedCode == null) {
            throw new BusinessException(ErrorCode.PASSWORD_RESET_CODE_NOT_FOUND);
        }
        if (!savedCode.equals(code)) {
            throw new BusinessException(ErrorCode.PASSWORD_RESET_CODE_INVALID);
        }

        String token = UUID.randomUUID().toString();
        passwordResetStore.saveToken(token, email);
        passwordResetStore.deleteCode(email);
        log.info("Password reset code verified: email={}", email);
        return token;
    }

    /**
     * 3단계 — 새 비밀번호 저장. 보안을 위해 해당 유저의 Refresh 토큰도 무효화한다.
     */
    @Transactional
    public void confirmReset(String token, String newPassword) {
        String email = passwordResetStore.getEmailByToken(token);
        if (email == null) {
            throw new BusinessException(ErrorCode.PASSWORD_RESET_TOKEN_INVALID);
        }

        UserMst user = userRepository.findByEmail(email)
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND));

        user.changePassword(passwordEncoder.encode(newPassword));
        passwordResetStore.deleteToken(token);
        refreshTokenStore.delete(user.getId());
        log.info("Password reset completed: userId={}", user.getId());
    }
}
