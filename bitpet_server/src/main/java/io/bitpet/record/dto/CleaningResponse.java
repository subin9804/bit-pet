package io.bitpet.record.dto;

import io.bitpet.record.domain.CleaningDtl;
import io.bitpet.record.domain.CleaningType;

import java.time.Instant;

public record CleaningResponse(
        Long id,
        Long petId,
        CleaningType cleaningType,
        Instant cleanedAt,
        String memo,
        Instant createdAt
) {
    public static CleaningResponse from(CleaningDtl c) {
        return new CleaningResponse(
                c.getId(), c.getPetId(), c.getCleaningType(),
                c.getCleanedAt(), c.getMemo(), c.getCreatedAt()
        );
    }
}
