package io.bitpet.record.dto;

import jakarta.validation.constraints.Size;

import java.time.Instant;

public record HealthLogUpdateRequest(
        @Size(max = 100) String symptom,
        String treatment,
        String memo,
        Instant recordedAt
) {}
