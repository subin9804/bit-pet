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
        return from(user, user.getProfileImageUrl());
    }

    /** profileImageUrl을 표시용으로 해석한 값(presigned GET 등)을 주입해 생성 */
    public static UserResponse from(UserMst user, String resolvedImageUrl) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getUserType().name(),
                resolvedImageUrl,
                user.getCreatedAt()
        );
    }
}
