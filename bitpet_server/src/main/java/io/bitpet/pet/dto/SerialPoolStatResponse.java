package io.bitpet.pet.dto;

import io.bitpet.pet.domain.SerialPoolStatMst;

import java.math.BigDecimal;
import java.time.Instant;

public record SerialPoolStatResponse(
        int serialLength,
        long totalCapacity,
        long usedCount,
        BigDecimal usageRate,
        boolean current,
        Instant expandedAt,
        Instant updatedAt
) {
    public static SerialPoolStatResponse from(SerialPoolStatMst s) {
        return new SerialPoolStatResponse(
                s.getSerialLength(), s.getTotalCapacity(), s.getUsedCount(),
                s.getUsageRate(), s.isCurrent(), s.getExpandedAt(), s.getUpdatedAt()
        );
    }
}
