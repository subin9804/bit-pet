package io.bitpet.auth.apple;

import com.fasterxml.jackson.databind.JsonNode;
import io.jsonwebtoken.Jwts;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;

/**
 * Apple REST API — 로그인 때 받은 authorization code 를 refresh 토큰으로 바꿔 두고,
 * 탈퇴할 때 그 토큰을 폐기(revoke)한다.
 *
 * <p>폐기는 App Store 심사 5.1.1(v) 요건이다: 앱 안에서 탈퇴하면 Apple 쪽 연결도
 * 끊어야 한다 (설정 > Apple ID > 'Apple로 로그인' 목록에서 사라진다).
 *
 * <p>호출에는 .p8 키로 서명한 client_secret 이 필요하다. 키가 설정되지 않았으면
 * {@link #enabled()} 가 false 이고 모든 호출을 건너뛴다 — 로그인 자체는 신원 토큰
 * 검증만으로 되므로 막지 않는다.
 */
@Slf4j
@Component
public class AppleTokenClient {

    private static final String BASE = "https://appleid.apple.com";

    private final AppleProperties properties;
    private final RestClient restClient = RestClient.create(BASE);
    private final PrivateKey privateKey;

    public AppleTokenClient(AppleProperties properties) {
        this.properties = properties;
        this.privateKey = loadKey(properties);
    }

    public boolean enabled() {
        return privateKey != null;
    }

    /** authorization code → refresh 토큰. 실패하거나 꺼져 있으면 null (로그인은 계속한다) */
    public String exchangeForRefreshToken(String authorizationCode) {
        if (!enabled() || authorizationCode == null || authorizationCode.isBlank()) return null;
        MultiValueMap<String, String> form = baseForm();
        form.add("code", authorizationCode);
        form.add("grant_type", "authorization_code");
        try {
            JsonNode body = restClient.post().uri("/auth/token")
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(form)
                    .retrieve()
                    .body(JsonNode.class);
            return body == null || !body.hasNonNull("refresh_token") ? null : body.get("refresh_token").asText();
        } catch (Exception e) {
            log.warn("Apple code exchange failed: {}", e.getMessage());
            return null;
        }
    }

    /** 탈퇴 후 호출. 실패해도 예외를 던지지 않는다 — 탈퇴는 이미 끝났다 */
    public void revokeQuietly(String refreshToken) {
        if (!enabled() || refreshToken == null) return;
        MultiValueMap<String, String> form = baseForm();
        form.add("token", refreshToken);
        form.add("token_type_hint", "refresh_token");
        try {
            restClient.post().uri("/auth/revoke")
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(form)
                    .retrieve()
                    .toBodilessEntity();
        } catch (Exception e) {
            log.warn("Apple token revoke failed: {}", e.getMessage());
        }
    }

    private MultiValueMap<String, String> baseForm() {
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("client_id", properties.clientId());
        form.add("client_secret", clientSecret());
        return form;
    }

    /** Apple 이 요구하는 ES256 JWT. 최대 6개월까지 유효하지만 매번 짧게 만든다 */
    private String clientSecret() {
        Instant now = Instant.now();
        return Jwts.builder()
                .header().keyId(properties.keyId()).and()
                .issuer(properties.teamId())
                .subject(properties.clientId())
                .audience().add(BASE).and()
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(Duration.ofMinutes(5))))
                .signWith(privateKey, Jwts.SIG.ES256)
                .compact();
    }

    private static PrivateKey loadKey(AppleProperties p) {
        if (p.keyPath() == null || p.keyPath().isBlank() || isBlank(p.teamId()) || isBlank(p.keyId())) {
            log.info("Apple key not configured — token revoke on withdrawal is disabled");
            return null;
        }
        Path path = Path.of(p.keyPath());
        if (!Files.isReadable(path)) {
            log.info("Apple key file not found ({}) — token revoke on withdrawal is disabled", path);
            return null;
        }
        try {
            String pem = Files.readString(path)
                    .replaceAll("-----(BEGIN|END) PRIVATE KEY-----", "")
                    .replaceAll("\\s", "");
            return KeyFactory.getInstance("EC")
                    .generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(pem)));
        } catch (Exception e) {
            // 키가 깨졌으면 기동을 막지 않고 끈다 — 로그인까지 막을 이유는 없다
            log.error("Apple key could not be loaded — token revoke on withdrawal is disabled", e);
            return null;
        }
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
