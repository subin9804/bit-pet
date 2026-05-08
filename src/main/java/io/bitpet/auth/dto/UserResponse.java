package io.bitpet.auth.dto;

import io.bitpet.auth.domain.UserMst;

import java.time.Instant;

public record UserResponse(
        Long id,
        String email,
        String nickname,
        String userType,
        String profileImageUrl,
        Instant createdAt
) {
    public static UserResponse from(UserMst user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getUserType().name(),
                user.getProfileImageUrl(),
                user.getCreatedAt()
        );
    }
}
