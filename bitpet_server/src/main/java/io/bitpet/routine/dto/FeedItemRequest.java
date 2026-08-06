package io.bitpet.routine.dto;

import io.bitpet.record.domain.FeedingSupplement;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record FeedItemRequest(
        @Size(max = 50) String foodType,
        BigDecimal amount,
        @Size(max = 10) String unit,
        @Size(max = 10) String sizeLabel,
        FeedingSupplement supplement,
        /** 거식 — 먹이 정보 없이 "거부했다"만 남긴다 */
        Boolean refused
) {
    public boolean isRefused() {
        return Boolean.TRUE.equals(refused);
    }
}
