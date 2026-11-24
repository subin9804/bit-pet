package io.bitpet.community.dto;

import io.bitpet.community.domain.UserSuspensionDtl;

import java.time.Instant;

/** 관리 페이지의 '정지 중' 목록 한 줄. endsAt 이 null 이면 영구. */
public record SuspensionResponse(
        Long id,
        Long userId,
        String nickname,
        Long reportId,
        String reason,
        Instant createdAt,
        Instant endsAt
) {
    public static SuspensionResponse of(UserSuspensionDtl s, String nickname) {
        return new SuspensionResponse(s.getId(), s.getUserId(), nickname, s.getReportId(),
                s.getReason(), s.getCreatedAt(), s.getEndsAt());
    }
}
