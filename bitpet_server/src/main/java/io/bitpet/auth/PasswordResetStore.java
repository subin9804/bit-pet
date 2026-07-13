package io.bitpet.auth;

import io.bitpet.auth.mail.MailProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

@Component
@RequiredArgsConstructor
public class PasswordResetStore {

    private static final String CODE_KEY_PREFIX = "bitpet:pwd-reset:code:";
    private static final String TOKEN_KEY_PREFIX = "bitpet:pwd-reset:token:";

    private final RedisTemplate<String, Object> redisTemplate;
    private final MailProperties mailProperties;

    public void saveCode(String email, String code) {
        redisTemplate.opsForValue().set(codeKey(email), code,
                Duration.ofMinutes(mailProperties.resetCodeTtlMinutes()));
    }

    public String getCode(String email) {
        Object value = redisTemplate.opsForValue().get(codeKey(email));
        return value == null ? null : value.toString();
    }

    public void deleteCode(String email) {
        redisTemplate.delete(codeKey(email));
    }

    public void saveToken(String token, String email) {
        redisTemplate.opsForValue().set(tokenKey(token), email,
                Duration.ofMinutes(mailProperties.resetTokenTtlMinutes()));
    }

    public String getEmailByToken(String token) {
        Object value = redisTemplate.opsForValue().get(tokenKey(token));
        return value == null ? null : value.toString();
    }

    public void deleteToken(String token) {
        redisTemplate.delete(tokenKey(token));
    }

    private String codeKey(String email) {
        return CODE_KEY_PREFIX + email;
    }

    private String tokenKey(String token) {
        return TOKEN_KEY_PREFIX + token;
    }
}
