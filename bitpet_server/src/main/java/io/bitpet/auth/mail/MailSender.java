package io.bitpet.auth.mail;

/**
 * 이메일 발송 추상화. 구현체는 SMTP({@link SmtpMailSender}) 하나 — 운영은 Resend SMTP, 로컬은 Gmail.
 * 제공자는 MAIL_HOST/MAIL_USERNAME/MAIL_PASSWORD 환경변수만 바꾸면 갈린다.
 * HTTP API 방식이 필요해지면 이 인터페이스의 새 구현체로 교체한다.
 */
public interface MailSender {

    void sendPasswordResetCode(String toEmail, String code);
}
