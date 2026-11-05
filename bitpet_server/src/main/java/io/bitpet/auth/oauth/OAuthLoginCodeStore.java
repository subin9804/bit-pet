package io.bitpet.auth.oauth;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.time.Duration;
import java.util.Base64;
import java.util.Optional;

/**
 * 소셜 로그인 성공 → 앱 사이에서 한 번만 쓰이는 교환 코드.
 *
 * <p>예전엔 성공 리다이렉트 URL 에 access·refresh 토큰을 그대로 붙였다. 그 URL 은
 * {@code tailog://} 커스텀 스킴이라 같은 스킴을 등록한 다른 앱이 가로챌 수 있고,
 * 브라우저 기록에도 남는다. 지금은 짧게 사는 코드만 넘기고, 앱이 그 코드와
 * 로그인 시작 때 숨겨둔 verifier 를 함께 보내야 토큰이 나온다
 * ({@code POST /auth/oauth/exchange}). 코드만 훔쳐서는 쓸 수 없다.
 *
 * <p>값은 {@code userId:challenge} — 기존 계정에 소셜이 방금 새로 붙었으면 뒤에
 * {@code :KAKAO} 처럼 제공자를 덧붙인다 (challenge 는 base64url 이라 콜론이 없다).
 * 조회와 삭제를 한 번에 해서 같은 코드로 두 번 교환하지 못하게 한다.
 */
@Component
@RequiredArgsConstructor
public class OAuthLoginCodeStore {

    private static final String KEY_PREFIX = "bitpet:oauth:code:";

    /** 브라우저가 닫히고 앱이 교환 요청을 보내기까지면 충분하다. */
    private static final Duration TTL = Duration.ofMinutes(2);

    private static final SecureRandom RANDOM = new SecureRandom();

    private final RedisTemplate<String, Object> redisTemplate;

    public String issue(Long userId, String challenge) {
        return issue(userId, challenge, null);
    }

    /** @param linkedProvider 이번 로그인에서 기존 계정에 새로 연결된 제공자. 없으면 null */
    public String issue(Long userId, String challenge, String linkedProvider) {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        String code = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        redisTemplate.opsForValue().set(KEY_PREFIX + code,
                userId + ":" + challenge + (linkedProvider == null ? "" : ":" + linkedProvider), TTL);
        return code;
    }

    /** 코드를 꺼내면서 지운다. 없거나 만료됐으면 빈 값. */
    public Optional<Entry> consume(String code) {
        Object value = redisTemplate.opsForValue().getAndDelete(KEY_PREFIX + code);
        if (value == null) return Optional.empty();
        String[] parts = value.toString().split(":");
        if (parts.length < 2) return Optional.empty();
        return Optional.of(new Entry(Long.valueOf(parts[0]), parts[1], parts.length > 2 ? parts[2] : null));
    }

    public record Entry(Long userId, String challenge, String linkedProvider) {}
}
