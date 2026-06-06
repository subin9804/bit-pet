package io.bitpet.record.dto;

import io.bitpet.record.domain.FeedingSupplement;
import io.bitpet.record.domain.FeedingDtl;

import java.math.BigDecimal;
import java.time.Instant;

public record FeedingResponse(
        Long id,
        Long petId,
        Long routineId,
        String foodType,
        BigDecimal amount,
        String unit,
        String sizeLabel,
        FeedingSupplement supplement,
        Instant fedAt,
        String memo,
        Instant createdAt
) {
    public static FeedingResponse from(FeedingDtl f) {
        return new FeedingResponse(
                f.getId(), f.getPetId(), f.getRoutineId(),
                f.getFoodType(), f.getAmount(), f.getUnit(),
                f.getSizeLabel(), f.getSupplement(),
                f.getFedAt(), f.getMemo(), f.getCreatedAt()
        );
    }
}
