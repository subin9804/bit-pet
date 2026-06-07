package io.bitpet.routine.dto;

import io.bitpet.routine.domain.RoutineLogStatus;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record RoutineCompleteIndividualRequest(
        @NotNull Long petId,
        @NotNull RoutineLogStatus status,
        Instant executedAt,
        // FEEDING: one row per item
        List<FeedItemRequest> feedItems,
        // CLEANING fields
        String cleaningType,
        // WEIGHT fields
        BigDecimal weightG,
        // shared
        String memo
) {}
