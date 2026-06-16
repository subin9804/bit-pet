package io.bitpet.group.redis;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.time.Duration;
import java.util.Optional;

/** OWNER가 발급하는 임시 그룹 초대코드. DB에 저장하지 않고 Redis TTL로만 관리한다. */
@Component
@RequiredArgsConstructor
public class GroupInviteCodeStore {

    private static final String KEY_PREFIX = "bitpet:group-invite:";
    private static final String CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final int    CODE_LEN   = 6;
    private static final int    CODE_RETRY = 10;
    public  static final Duration TTL      = Duration.ofMinutes(5);

    private final RedisTemplate<String, Object> redisTemplate;
    private final SecureRandom random = new SecureRandom();

    /** 그룹에 대해 새 코드를 발급하고 5분 TTL로 저장한다. */
    public String issue(Long groupId) {
        for (int i = 0; i < CODE_RETRY; i++) {
            String code = randomCode();
            Boolean set = redisTemplate.opsForValue()
                    .setIfAbsent(key(code), groupId, TTL);
            if (Boolean.TRUE.equals(set)) {
                return code;
            }
        }
        throw new IllegalStateException("초대코드 발급에 실패했습니다");
    }

    public Optional<Long> findGroupId(String code) {
        Object value = redisTemplate.opsForValue().get(key(code));
        return Optional.ofNullable(value).map(v -> ((Number) v).longValue());
    }

    private String randomCode() {
        StringBuilder sb = new StringBuilder(CODE_LEN);
        for (int j = 0; j < CODE_LEN; j++) {
            sb.append(CODE_CHARS.charAt(random.nextInt(CODE_CHARS.length())));
        }
        return sb.toString();
    }

    private String key(String code) {
        return KEY_PREFIX + code;
    }
}
