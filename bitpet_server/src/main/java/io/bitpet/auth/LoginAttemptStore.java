package io.bitpet.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Locale;

/**
 * 이메일 로그인 실패 횟수 — 계정 단위 무차별 대입 차단 (2026-11-09, 출시 전 보안 점검).
 *
 * <p>{@value #MAX_FAILURES}번 틀리면 첫 실패부터 {@link #WINDOW} 동안 그 이메일로는 비밀번호를 대조하지 않는다.
 * 창은 첫 실패 시각에 고정된다 — 실패할 때마다 늘리면 공격자가 정상 사용자를 영영 잠가둘 수 있다.
 *
 * <p>가입 안 된 이메일도 똑같이 센다. 잠금 여부가 가입 여부를 드러내면 안 된다.
 * IP 단위 제한(여러 계정에 같은 비밀번호를 뿌리는 공격)은 nginx {@code limit_req} 가 맡는다.
 */
@Component
@RequiredArgsConstructor
public class LoginAttemptStore {

    static final int MAX_FAILURES = 5;
    static final Duration WINDOW = Duration.ofMinutes(10);

    private static final String KEY_PREFIX = "bitpet:login-fail:";

    private final RedisTemplate<String, Object> redisTemplate;

    public boolean isLocked(String email) {
        Object value = redisTemplate.opsForValue().get(key(email));
        return value != null && Long.parseLong(value.toString()) >= MAX_FAILURES;
    }

    public void recordFailure(String email) {
        String key = key(email);
        Long n = redisTemplate.opsForValue().increment(key);
        if (n != null && n == 1) redisTemplate.expire(key, WINDOW);
    }

    public void reset(String email) {
        redisTemplate.delete(key(email));
    }

    private String key(String email) {
        return KEY_PREFIX + email.trim().toLowerCase(Locale.ROOT);
    }
}
