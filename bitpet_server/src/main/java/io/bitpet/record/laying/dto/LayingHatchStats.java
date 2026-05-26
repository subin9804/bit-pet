package io.bitpet.record.laying.dto;

public record LayingHatchStats(
        long hatchedCount,
        long failedCount,
        long pendingCount
) {}
