package io.bitpet.routine.dto;

import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.domain.RoutineType;

import java.time.Instant;
import java.util.List;

public record TodayRoutineResponse(
        Long routineId,
        String title,
        RoutineType routineType,
        Instant nextDueAt,
        List<PetTodayStatus> pets
) {
    public record PetTodayStatus(
            Long petId,
            String petName,
            boolean completedToday,
            Long logId,
            Instant executedAt
    ) {}

    public static TodayRoutineResponse from(RoutineMst routine, List<PetTodayStatus> pets) {
        return new TodayRoutineResponse(
                routine.getId(),
                routine.getTitle(),
                routine.getRoutineType(),
                routine.getNextDueAt(),
                pets
        );
    }
}
