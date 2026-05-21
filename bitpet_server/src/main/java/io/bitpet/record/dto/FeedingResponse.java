package io.bitpet.record.dto;

import io.bitpet.record.domain.FeedResponse;
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
        FeedResponse feedResponse,
        Instant fedAt,
        String memo,
        Instant createdAt
) {
    public static FeedingResponse from(FeedingDtl f) {
        return new FeedingResponse(
                f.getId(), f.getPetId(), f.getRoutineId(),
                f.getFoodType(), f.getAmount(), f.getUnit(),
                f.getFeedResponse(), f.getFedAt(), f.getMemo(), f.getCreatedAt()
        );
    }
}
