package io.bitpet.notification.dto;

import io.bitpet.notification.domain.PushBroadcastDtl;

import java.time.Instant;

public record BroadcastResponse(
        Long id,
        String title,
        String body,
        boolean marketing,
        int targetCount,
        Instant createdAt
) {
    public static BroadcastResponse from(PushBroadcastDtl b) {
        return new BroadcastResponse(b.getId(), b.getTitle(), b.getBody(), b.isMarketing(),
                b.getTargetCount(), b.getCreatedAt());
    }
}
