package io.bitpet.auth.mail;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "bitpet.mail")
public record MailProperties(
        String from,
        int resetCodeTtlMinutes,
        int resetTokenTtlMinutes
) {}
