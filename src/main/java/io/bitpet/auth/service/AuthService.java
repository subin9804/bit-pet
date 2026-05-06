package io.bitpet.auth.service;

import io.bitpet.auth.domain.User;
import io.bitpet.auth.dto.LoginRequest;
import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.dto.TokenResponse;
import io.bitpet.auth.dto.UserResponse;
import io.bitpet.auth.jwt.JwtTokenProvider;
import io.bitpet.auth.jwt.RefreshTokenStore;
import io.bitpet.auth.repository.UserRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final RefreshTokenStore refreshTokenStore;

    @Transactional
    public UserResponse signup(SignupRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_ALREADY_EXISTS);
        }
        String passwordHash = passwordEncoder.encode(request.password());
        User user = User.createLocal(request.email(), passwordHash, request.nickname());
        User saved = userRepository.save(user);
        log.info("User signed up: id={}, email={}", saved.getId(), saved.getEmail());
        return UserResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public TokenResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_INVALID_CREDENTIALS));

        if (user.getPasswordHash() == null
                || !passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new BusinessException(ErrorCode.AUTH_INVALID_CREDENTIALS);
        }
        if (!user.isEnabled()) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "Account disabled");
        }

        return issueTokens(user);
    }

    public TokenResponse refresh(String refreshToken) {
        Long userId;
        try {
            userId = tokenProvider.extractUserIdFromRefreshToken(refreshToken);
        } catch (JwtException e) {
            throw new BusinessException(ErrorCode.AUTH_INVALID_TOKEN, e.getMessage());
        }

        if (!refreshTokenStore.matches(userId, refreshToken)) {
            throw new BusinessException(ErrorCode.AUTH_REFRESH_TOKEN_NOT_FOUND);
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND));

        return issueTokens(user);
    }

    public void logout(Long userId) {
        refreshTokenStore.delete(userId);
    }

    private TokenResponse issueTokens(User user) {
        String access = tokenProvider.issueAccessToken(user.getId(), user.getEmail(), user.getRole().name());
        String refresh = tokenProvider.issueRefreshToken(user.getId());
        refreshTokenStore.save(user.getId(), refresh);
        return TokenResponse.bearer(access, refresh);
    }
}
