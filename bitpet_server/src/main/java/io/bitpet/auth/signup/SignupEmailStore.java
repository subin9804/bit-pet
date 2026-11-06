package io.bitpet.auth.signup;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * 가입 이메일 인증 상태 (Redis). 비밀번호 재설정({@code PasswordResetStore})과 키를 나눈다 —
 * 같은 주소로 두 흐름이 동시에 돌 수 있다.
 *
 * <ul>
 *   <li>code: 이메일 → 6자리 코드</li>
 *   <li>attempts: 이메일 → 오답 수 (코드와 같이 만료)</li>
 *   <li>cooldown: 이메일 → 재발송 대기 표시</li>
 *   <li>verified: 토큰 → 이메일. 가입 요청이 이 토큰을 들고 온다</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
public class SignupEmailStore {

    private static final String PREFIX = "bitpet:signup-email:";

    private final RedisTemplate<String, Object> redisTemplate;

    public void saveCode(String email, String code, Duration ttl) {
        redisTemplate.opsForValue().set(codeKey(email), code, ttl);
        redisTemplate.delete(attemptsKey(email));
    }

    public String getCode(String email) {
        Object v = redisTemplate.opsForValue().get(codeKey(email));
        return v == null ? null : v.toString();
    }

    public void deleteCode(String email) {
        redisTemplate.delete(codeKey(email));
        redisTemplate.delete(attemptsKey(email));
    }

    /** 오답 한 번 기록하고 누적 횟수를 돌려준다 */
    public long recordFailure(String email, Duration ttl) {
        String key = attemptsKey(email);
        Long n = redisTemplate.opsForValue().increment(key);
        if (n != null && n == 1) redisTemplate.expire(key, ttl);
        return n == null ? 1 : n;
    }

    /** 쿨다운을 건다. 이미 걸려 있으면 false */
    public boolean tryStartCooldown(String email, Duration ttl) {
        Boolean set = redisTemplate.opsForValue().setIfAbsent(PREFIX + "cooldown:" + email, "1", ttl);
        return Boolean.TRUE.equals(set);
    }

    public void saveVerified(String token, String email, Duration ttl) {
        redisTemplate.opsForValue().set(verifiedKey(token), email, ttl);
    }

    public String getVerifiedEmail(String token) {
        Object v = redisTemplate.opsForValue().get(verifiedKey(token));
        return v == null ? null : v.toString();
    }

    public void deleteVerified(String token) {
        redisTemplate.delete(verifiedKey(token));
    }

    private static String codeKey(String email) {
        return PREFIX + "code:" + email;
    }

    private static String attemptsKey(String email) {
        return PREFIX + "attempts:" + email;
    }

    private static String verifiedKey(String token) {
        return PREFIX + "verified:" + token;
    }
}
