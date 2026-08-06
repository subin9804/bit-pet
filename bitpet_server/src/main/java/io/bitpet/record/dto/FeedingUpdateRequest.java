package io.bitpet.record.dto;

import io.bitpet.record.domain.FeedingSupplement;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * 급여 기록 부분 수정. null 은 "그대로 두기".
 *
 * <p>{@code refused} 가 넘어오면 급여↔거식 전환이라 먹이 정보를 통째로 갈아끼운다.
 * (거식으로 바꾸면 먹이 종류·양·영양제가 모두 지워진다)
 */
public record FeedingUpdateRequest(
        @Size(max = 50) String foodType,
        BigDecimal amount,
        @Size(max = 10) String unit,
        @Size(max = 10) String sizeLabel,
        FeedingSupplement supplement,
        Instant fedAt,
        String memo,
        Boolean refused
) {}
