package io.bitpet.auth.service;

import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.dto.LoginRequest;
import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.dto.TokenResponse;
import io.bitpet.auth.dto.UserResponse;
import io.bitpet.auth.jwt.JwtTokenProvider;
import io.bitpet.auth.jwt.RefreshTokenStore;
import io.bitpet.auth.repository.UserMstRepository;
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

    private final UserMstRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final RefreshTokenStore refreshTokenStore;

    @Transactional
    public UserResponse signup(SignupRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_ALREADY_EXISTS);
        }
        String passwordHash = passwordEncoder.encode(request.password());
        UserMst user = UserMst.createLocal(request.email(), passwordHash, request.nickname());
        UserMst saved = userRepository.save(user);
        log.info("User signed up: id={}, email={}", saved.getId(), saved.getEmail());
        return UserResponse.from(saved);
    }

    @Transactional
    public TokenResponse login(LoginRequest request) {
        UserMst user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_INVALID_CREDENTIALS));

        if (user.getPasswordHash() == null
                || !passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new BusinessException(ErrorCode.AUTH_INVALID_CREDENTIALS);
        }

        user.markLoggedIn();
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

        UserMst user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND));

        return issueTokens(user);
    }

    public void logout(Long userId) {
        refreshTokenStore.delete(userId);
    }

    @Transactional
    public void withdraw(Long userId) {
        UserMst user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND));
        user.softDelete();
        refreshTokenStore.delete(userId);
        log.info("User withdrew: id={}, deletedAt={}", userId, user.getDeletedAt());
    }

    private TokenResponse issueTokens(UserMst user) {
        String access = tokenProvider.issueAccessToken(user.getId(), user.getEmail(), user.getUserType().name());
        String refresh = tokenProvider.issueRefreshToken(user.getId());
        refreshTokenStore.save(user.getId(), refresh);
        return TokenResponse.bearer(access, refresh);
    }
}
