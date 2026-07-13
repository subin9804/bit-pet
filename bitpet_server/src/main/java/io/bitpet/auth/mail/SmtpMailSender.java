package io.bitpet.auth.mail;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Primary;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Slf4j
@Primary
@Service
@RequiredArgsConstructor
public class SmtpMailSender implements MailSender {

    private static final String RESET_CODE_SUBJECT = "[Bit-Pet] 비밀번호 재설정 인증 코드";
    private static final String RESET_CODE_BODY = """
            안녕하세요, Bit-Pet입니다.

            비밀번호 재설정 인증 코드를 알려드립니다.

            인증 코드: %s

            이 코드는 5분 후 만료됩니다.
            본인이 요청하지 않은 경우 이 메일을 무시해 주세요.""";

    private final JavaMailSender javaMailSender;
    private final MailProperties mailProperties;

    @Override
    public void sendPasswordResetCode(String toEmail, String code) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(mailProperties.from());
        message.setTo(toEmail);
        message.setSubject(RESET_CODE_SUBJECT);
        message.setText(RESET_CODE_BODY.formatted(code));

        javaMailSender.send(message);
        log.info("Password reset code mail sent: to={}", toEmail);
    }
}
