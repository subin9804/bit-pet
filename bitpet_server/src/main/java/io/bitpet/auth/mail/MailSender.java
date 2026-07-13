package io.bitpet.auth.mail;

/**
 * 이메일 발송 추상화. 현재 구현체는 Gmail SMTP({@link SmtpMailSender})이며,
 * AWS SES 전환 시 이 인터페이스의 새 구현체로 교체한다.
 */
public interface MailSender {

    void sendPasswordResetCode(String toEmail, String code);
}
