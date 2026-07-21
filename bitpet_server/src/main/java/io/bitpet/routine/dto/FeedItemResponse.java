package io.bitpet.routine.dto;

import io.bitpet.record.domain.FeedingDtl;
import io.bitpet.record.domain.FeedingSupplement;

import java.math.BigDecimal;

/** 루틴 완료 로그에 연결된 급여 항목 1건 (재로딩용) */
public record FeedItemResponse(
        String foodType,
        BigDecimal amount,
        String unit,
        String sizeLabel,
        FeedingSupplement supplement
) {
    public static FeedItemResponse from(FeedingDtl d) {
        return new FeedItemResponse(
                d.getFoodType(), d.getAmount(), d.getUnit(),
                d.getSizeLabel(), d.getSupplement());
    }
}
