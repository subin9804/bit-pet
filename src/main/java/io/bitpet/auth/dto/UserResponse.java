package io.bitpet.auth.dto;

import io.bitpet.auth.domain.User;

import java.time.Instant;

public record UserResponse(
        Long id,
        String email,
        String nickname,
        String role,
        String provider,
        Instant createdAt
) {
    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getNickname(),
                user.getRole().name(),
                user.getProvider().name(),
                user.getCreatedAt()
        );
    }
}
