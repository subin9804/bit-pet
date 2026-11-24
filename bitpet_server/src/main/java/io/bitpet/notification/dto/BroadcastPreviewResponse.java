package io.bitpet.notification.dto;

/**
 * 보내기 전에 보여 줄 대상 수. {@code marketingQuietHours} 가 true 면 지금은 광고를 못 보낸다(21~08시).
 */
public record BroadcastPreviewResponse(
        int allCount,
        int marketingCount,
        boolean marketingQuietHours
) {}
