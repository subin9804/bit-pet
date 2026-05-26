package io.bitpet.record.laying.dto;

import io.bitpet.record.laying.domain.HatchStatus;
import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;

public record HatchCreateRequest(
        OffsetDateTime hatchedAt,
        @NotNull HatchStatus status,
        String memo
) {}
