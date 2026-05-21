package io.bitpet.routine.dto;

import io.bitpet.routine.domain.RoutineLogDtl;
import io.bitpet.routine.domain.RoutineLogStatus;

import java.time.Instant;
import java.util.Map;

public record RoutineLogResponse(
        Long id,
        Long routineId,
        Long petId,
        RoutineLogStatus status,
        Instant executedAt,
        Map<String, Object> extraData,
        String memo,
        Instant createdAt
) {
    public static RoutineLogResponse from(RoutineLogDtl log) {
        return new RoutineLogResponse(
                log.getId(), log.getRoutineId(), log.getPetId(),
                log.getStatus(), log.getExecutedAt(),
                log.getExtraData(), log.getMemo(), log.getCreatedAt()
        );
    }
}
