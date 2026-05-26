package io.bitpet.record.laying.dto;

import io.bitpet.record.laying.domain.HatchStatus;

import java.time.OffsetDateTime;

public record HatchUpdateRequest(
        OffsetDateTime hatchedAt,
        HatchStatus status,
        Long hatchedPetId,
        String memo
) {}
