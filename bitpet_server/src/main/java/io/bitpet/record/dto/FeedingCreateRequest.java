package io.bitpet.record.dto;

import io.bitpet.record.domain.FeedingSupplement;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * 급여 기록 생성.
 *
 * <p>{@code refused=true} 면 거식(먹이 거부) 기록이다. 이때 foodType 이하 먹이 정보는
 * 무시되고 memo 만 남는다. 거식이 아닌데 foodType 이 비어 있으면 {@code food_type = ''}
 * — "급여는 했고 뭘 줬는지 안 적음" 으로 저장된다 (2026-10-28, FAB 빠른 급여 기록).
 */
public record FeedingCreateRequest(
        @Size(max = 50) String foodType,
        BigDecimal amount,
        @Size(max = 10) String unit,
        @Size(max = 10) String sizeLabel,
        FeedingSupplement supplement,
        @NotNull Instant fedAt,
        String memo,
        Boolean refused
) {
    public boolean isRefused() {
        return Boolean.TRUE.equals(refused);
    }
}
