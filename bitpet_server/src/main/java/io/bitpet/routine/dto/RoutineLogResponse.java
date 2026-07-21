package io.bitpet.routine.dto;

import io.bitpet.routine.domain.RoutineLogDtl;
import io.bitpet.routine.domain.RoutineLogStatus;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record RoutineLogResponse(
        Long id,
        Long routineId,
        Long petId,
        RoutineLogStatus status,
        Instant executedAt,
        String memo,
        BigDecimal weightG,
        List<FeedItemResponse> feedItems,
        Instant createdAt
) {
    /** memo·부가정보 없이 (완료 직후 응답 등) */
    public static RoutineLogResponse from(RoutineLogDtl log) {
        return from(log, null, null, List.of());
    }

    /** 연결된 dtl 에서 파생한 memo·weightG·feedItems 를 포함해 반환 */
    public static RoutineLogResponse from(RoutineLogDtl log, String memo,
                                          BigDecimal weightG, List<FeedItemResponse> feedItems) {
        return new RoutineLogResponse(
                log.getId(), log.getRoutineId(), log.getPetId(),
                log.getStatus(), log.getExecutedAt(),
                memo, weightG, feedItems != null ? feedItems : List.of(),
                log.getCreatedAt()
        );
    }
}
