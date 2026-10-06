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
        boolean refused,
        String routineTitle, // 루틴 완료로 생성된 기록이면 해당 루틴 제목 (수동 기록은 null)
        Instant createdAt
) {
    public static FeedingResponse from(FeedingDtl f) {
        return from(f, null);
    }

    public static FeedingResponse from(FeedingDtl f, String routineTitle) {
        return new FeedingResponse(
                f.getId(), f.getPetId(), f.getRoutineId(),
                f.getFoodType(), f.getAmount(), f.getUnit(),
                f.getSizeLabel(), f.getSupplement(),
                f.getFedAt(), f.getMemo(), f.isRefused(),
                routineTitle,
                f.getCreatedAt()
        );
    }
}
