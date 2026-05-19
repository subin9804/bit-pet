package io.bitpet.record.dto;

import io.bitpet.record.domain.CleaningType;

import java.time.Instant;

public record CleaningUpdateRequest(
        CleaningType cleaningType,
        Instant cleanedAt,
        String memo
) {}
