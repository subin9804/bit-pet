package io.bitpet.routine.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record RoutineCompleteBatchRequest(
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
