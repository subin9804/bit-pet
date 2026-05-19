package io.bitpet.routine.dto;

import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.domain.RoutineType;

import java.time.Instant;

public record RoutineResponse(
        Long id,
        Long petId,
        RoutineType routineType,
        String title,
        int cycleDays,
        Instant lastExecutedAt,
        Instant nextDueAt,
        boolean active,
        String memo,
        Instant createdAt,
        Instant updatedAt
) {
    public static RoutineResponse from(RoutineMst r) {
        return new RoutineResponse(
                r.getId(), r.getPetId(), r.getRoutineType(), r.getTitle(),
                r.getCycleDays(), r.getLastExecutedAt(), r.getNextDueAt(),
                r.isActive(), r.getMemo(), r.getCreatedAt(), r.getUpdatedAt()
        );
    }
}
