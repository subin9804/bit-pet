package io.bitpet.record.dto;

import io.bitpet.record.domain.CleaningType;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public record CleaningCreateRequest(
        @NotNull CleaningType cleaningType,
        @NotNull Instant cleanedAt,
        String memo
) {}
