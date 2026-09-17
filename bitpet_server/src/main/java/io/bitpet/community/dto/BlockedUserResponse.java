package io.bitpet.community.dto;

import java.time.Instant;

/** 차단 목록 한 줄. 해제 버튼을 달려면 userId 가 필요하다 */
public record BlockedUserResponse(
        Long userId,
        String nickname,
        String profileImageUrl,
        Instant blockedAt
) {}
