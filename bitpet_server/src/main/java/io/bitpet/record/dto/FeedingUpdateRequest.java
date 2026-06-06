package io.bitpet.record.dto;

import io.bitpet.record.domain.FeedingSupplement;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;

public record FeedingUpdateRequest(
        @Size(max = 50) String foodType,
        BigDecimal amount,
        @Size(max = 10) String unit,
        @Size(max = 10) String sizeLabel,
        FeedingSupplement supplement,
        Instant fedAt,
        String memo
) {}
