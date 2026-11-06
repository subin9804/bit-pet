package io.bitpet.auth.apple;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtClaimValidator;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Collection;
import java.util.HexFormat;

/**
 * 앱이 받은 Apple 신원 토큰(id_token)을 검증한다.
 *
 * <p>서명(Apple 공개키 JWKS) · 발급자 · 만료 · aud(= 우리 번들 ID) · nonce 를 본다.
 * aud 를 안 보면 <b>다른 앱</b>에서 받은 Apple 토큰으로 우리 계정에 들어올 수 있다.
 * nonce 는 앱이 로그인마다 새로 만든 원문의 SHA-256(hex) 이 토큰에 박혀 오는 것 —
 * 훔친 토큰을 다시 내미는 재전송을 막는다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AppleIdTokenVerifier {

    static final String ISSUER = "https://appleid.apple.com";
    private static final String JWKS_URI = "https://appleid.apple.com/auth/keys";

    private final AppleProperties properties;
    private volatile NimbusJwtDecoder decoder;

    public Jwt verify(String identityToken, String rawNonce) {
        Jwt jwt;
        try {
            jwt = decoder().decode(identityToken);
        } catch (JwtException e) {
            log.warn("Apple identity token rejected: {}", e.getMessage());
            throw new BusinessException(ErrorCode.AUTH_INVALID_TOKEN, "Apple 로그인 정보를 확인하지 못했어요");
        }
        String expected = sha256Hex(rawNonce);
        Object nonce = jwt.getClaims().get("nonce");
        if (nonce == null || !MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.US_ASCII),
                nonce.toString().getBytes(StandardCharsets.US_ASCII))) {
            throw new BusinessException(ErrorCode.AUTH_INVALID_TOKEN, "Apple 로그인 정보를 확인하지 못했어요");
        }
        return jwt;
    }

    private NimbusJwtDecoder decoder() {
        NimbusJwtDecoder d = decoder;
        if (d == null) {
            synchronized (this) {
                if (decoder == null) {
                    NimbusJwtDecoder built = NimbusJwtDecoder.withJwkSetUri(JWKS_URI).build();
                    built.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                            JwtValidators.createDefaultWithIssuer(ISSUER),
                            new JwtClaimValidator<Collection<String>>("aud",
                                    aud -> aud != null && aud.contains(properties.clientId()))));
                    decoder = built;
                }
                d = decoder;
            }
        }
        return d;
    }

    static String sha256Hex(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
