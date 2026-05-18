package io.bitpet.record.dto;

import io.bitpet.record.domain.WeightDtl;
import io.bitpet.record.domain.WeightSource;

import java.math.BigDecimal;
import java.time.Instant;

public record WeightResponse(
        Long id,
        Long petId,
        BigDecimal weightG,
        Instant measuredAt,
        WeightSource source,
        String memo,
        Instant createdAt
) {
    public static WeightResponse from(WeightDtl w) {
        return new WeightResponse(
                w.getId(), w.getPetId(), w.getWeightG(),
                w.getMeasuredAt(), w.getSource(), w.getMemo(), w.getCreatedAt()
        );
    }
}
