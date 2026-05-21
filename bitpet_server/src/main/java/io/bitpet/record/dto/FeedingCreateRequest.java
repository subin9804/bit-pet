package io.bitpet.record.dto;

import io.bitpet.record.domain.FeedResponse;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;

public record FeedingCreateRequest(
        @NotBlank @Size(max = 50) String foodType,
        BigDecimal amount,
        @Size(max = 10) String unit,
        FeedResponse feedResponse,
        @NotNull Instant fedAt,
        String memo
) {}
