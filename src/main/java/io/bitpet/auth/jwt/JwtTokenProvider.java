package io.bitpet.auth.jwt;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtTokenProvider {

    private static final String CLAIM_EMAIL = "email";
    private static final String CLAIM_ROLE = "role";
    private static final String CLAIM_TYPE = "type";
    private static final String TYPE_ACCESS = "access";
    private static final String TYPE_REFRESH = "refresh";

    private final JwtProperties properties;
    private SecretKey key;

    @PostConstruct
    void init() {
        byte[] keyBytes = properties.secret().getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length < 32) {
            throw new IllegalStateException("bitpet.jwt.secret must be at least 32 bytes (256 bits) for HS256");
        }
        this.key = Keys.hmacShaKeyFor(keyBytes);
    }

    public String issueAccessToken(Long userId, String email, String role) {
        Instant now = Instant.now();
        Instant exp = now.plus(properties.accessTokenValidity());
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .issuer(properties.issuer())
                .issuedAt(Date.from(now))
                .expiration(Date.from(exp))
                .claim(CLAIM_EMAIL, email)
                .claim(CLAIM_ROLE, role)
                .claim(CLAIM_TYPE, TYPE_ACCESS)
                .signWith(key, Jwts.SIG.HS256)
                .compact();
    }

    public String issueRefreshToken(Long userId) {
        Instant now = Instant.now();
        Instant exp = now.plus(properties.refreshTokenValidity());
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .issuer(properties.issuer())
                .issuedAt(Date.from(now))
                .expiration(Date.from(exp))
                .claim(CLAIM_TYPE, TYPE_REFRESH)
                .signWith(key, Jwts.SIG.HS256)
                .compact();
    }

    public boolean isValidAccessToken(String token) {
        return parse(token).map(c -> TYPE_ACCESS.equals(c.get(CLAIM_TYPE, String.class))).orElse(false);
    }

    public Long extractUserIdFromRefreshToken(String token) {
        Claims claims = parse(token)
                .filter(c -> TYPE_REFRESH.equals(c.get(CLAIM_TYPE, String.class)))
                .orElseThrow(() -> new JwtException("Not a valid refresh token"));
        return Long.valueOf(claims.getSubject());
    }

    public Authentication toAuthentication(String accessToken) {
        Claims claims = parse(accessToken)
                .orElseThrow(() -> new JwtException("Invalid token"));
        Long userId = Long.valueOf(claims.getSubject());
        String email = claims.get(CLAIM_EMAIL, String.class);
        String role = claims.get(CLAIM_ROLE, String.class);

        AuthPrincipal principal = new AuthPrincipal(userId, email, role);
        var authority = new SimpleGrantedAuthority("ROLE_" + (role == null ? "USER" : role));
        return new UsernamePasswordAuthenticationToken(principal, accessToken, List.of(authority));
    }

    private java.util.Optional<Claims> parse(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            return java.util.Optional.of(claims);
        } catch (ExpiredJwtException e) {
            log.debug("JWT expired: {}", e.getMessage());
            return java.util.Optional.empty();
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("Invalid JWT: {}", e.getMessage());
            return java.util.Optional.empty();
        }
    }
}
