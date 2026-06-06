package io.bitpet.routine.dto;

import io.bitpet.record.domain.FeedingSupplement;
import io.bitpet.routine.domain.RoutineLogStatus;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;

public record RoutineCompleteIndividualRequest(
        @NotNull Long petId,
        @NotNull RoutineLogStatus status,
        Instant executedAt,
        // FEEDING fields
        String foodType,
        BigDecimal amount,
        String unit,
        String sizeLabel,
        FeedingSupplement supplement,
        // CLEANING fields
        String cleaningType,
        // WEIGHT fields
        BigDecimal weightG,
        // shared
        String memo
) {}
