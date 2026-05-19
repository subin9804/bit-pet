package io.bitpet.auth.jwt;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class RefreshTokenStore {

    private static final String KEY_PREFIX = "bitpet:refresh:";

    private final RedisTemplate<String, Object> redisTemplate;
    private final JwtProperties jwtProperties;

    public void save(Long userId, String refreshToken) {
        redisTemplate.opsForValue().set(key(userId), refreshToken, jwtProperties.refreshTokenValidity());
    }

    public Optional<String> find(Long userId) {
        Object value = redisTemplate.opsForValue().get(key(userId));
        return Optional.ofNullable(value).map(Object::toString);
    }

    public boolean matches(Long userId, String refreshToken) {
        return find(userId).map(refreshToken::equals).orElse(false);
    }

    public void delete(Long userId) {
        redisTemplate.delete(key(userId));
    }

    public Duration ttl() {
        return jwtProperties.refreshTokenValidity();
    }

    private String key(Long userId) {
        return KEY_PREFIX + userId;
    }
}
