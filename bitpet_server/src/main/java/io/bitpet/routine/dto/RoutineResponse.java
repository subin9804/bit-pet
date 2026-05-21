package io.bitpet.routine.dto;

import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.domain.RoutineType;

import java.time.Instant;
import java.time.LocalTime;
import java.util.List;

public record RoutineResponse(
        Long id,
        Long userId,
        RoutineType routineType,
        String title,
        int cycleDays,
        LocalTime alarmTime,
        boolean alarmEnabled,
        Instant lastExecutedAt,
        Instant nextDueAt,
        boolean active,
        String memo,
        List<Long> petIds,
        int petCount,
        Instant createdAt,
        Instant updatedAt
) {
    public static RoutineResponse from(RoutineMst r, List<Long> petIds) {
        return new RoutineResponse(
                r.getId(), r.getUserId(), r.getRoutineType(), r.getTitle(),
                r.getCycleDays(), r.getAlarmTime(), r.isAlarmEnabled(),
                r.getLastExecutedAt(), r.getNextDueAt(),
                r.isActive(), r.getMemo(),
                petIds, petIds.size(),
                r.getCreatedAt(), r.getUpdatedAt()
        );
    }

    public static RoutineResponse from(RoutineMst r) {
        return from(r, List.of());
    }
}
