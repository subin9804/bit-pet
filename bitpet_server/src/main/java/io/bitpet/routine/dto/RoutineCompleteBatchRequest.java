package io.bitpet.routine.dto;

import io.bitpet.record.domain.FeedResponse;

import java.math.BigDecimal;
import java.time.Instant;

public record RoutineCompleteBatchRequest(
        Instant executedAt,
        // FEEDING fields
        String foodType,
        BigDecimal amount,
        String unit,
        FeedResponse feedResponse,
        // CLEANING fields
        String cleaningType,
        // WEIGHT fields
        BigDecimal weightG,
        // shared
        String memo
) {}
