package io.bitpet.record.dto;

import io.bitpet.record.domain.FeedingDtl;

import java.math.BigDecimal;
import java.time.Instant;

public record FeedingResponse(
        Long id,
        Long petId,
        String foodType,
        BigDecimal amount,
        String unit,
        Instant fedAt,
        String memo,
        Instant createdAt
) {
    public static FeedingResponse from(FeedingDtl f) {
        return new FeedingResponse(
                f.getId(), f.getPetId(), f.getFoodType(),
                f.getAmount(), f.getUnit(), f.getFedAt(), f.getMemo(), f.getCreatedAt()
        );
    }
}
