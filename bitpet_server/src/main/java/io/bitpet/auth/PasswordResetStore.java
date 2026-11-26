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
    private static final String ATTEMPTS_KEY_PREFIX = "bitpet:pwd-reset:attempts:";
    private static final String COOLDOWN_KEY_PREFIX = "bitpet:pwd-reset:cooldown:";

    private final RedisTemplate<String, Object> redisTemplate;
    private final MailProperties mailProperties;

    public void saveCode(String email, String code) {
        redisTemplate.opsForValue().set(codeKey(email), code,
                Duration.ofMinutes(mailProperties.resetCodeTtlMinutes()));
        redisTemplate.delete(attemptsKey(email));
    }

    public String getCode(String email) {
        Object value = redisTemplate.opsForValue().get(codeKey(email));
        return value == null ? null : value.toString();
    }

    public void deleteCode(String email) {
        redisTemplate.delete(codeKey(email));
        redisTemplate.delete(attemptsKey(email));
    }

    /** 오답 한 번 기록하고 누적 횟수를 돌려준다. 코드와 같이 만료 */
    public long recordFailure(String email) {
        String key = attemptsKey(email);
        Long n = redisTemplate.opsForValue().increment(key);
        if (n != null && n == 1) {
            redisTemplate.expire(key, Duration.ofMinutes(mailProperties.resetCodeTtlMinutes()));
        }
        return n == null ? 1 : n;
    }

    /** 재발송 대기를 건다. 이미 걸려 있으면 false */
    public boolean tryStartCooldown(String email) {
        Boolean set = redisTemplate.opsForValue().setIfAbsent(COOLDOWN_KEY_PREFIX + email, "1",
                Duration.ofSeconds(mailProperties.resetResendCooldownSeconds()));
        return Boolean.TRUE.equals(set);
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

    private String attemptsKey(String email) {
        return ATTEMPTS_KEY_PREFIX + email;
    }

    private String tokenKey(String token) {
        return TOKEN_KEY_PREFIX + token;
    }
}
