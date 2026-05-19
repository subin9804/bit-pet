package io.bitpet.record.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

public record HealthLogCreateRequest(
        @Size(max = 100) String symptom,
        String treatment,
        String memo,
        @NotNull Instant recordedAt
) {}
