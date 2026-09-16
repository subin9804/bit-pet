package io.bitpet.routine.dto;

import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.domain.RoutineType;

import java.time.format.DateTimeFormatter;
import java.util.List;

public record TodayRoutineResponse(
        Long id,
        String title,
        RoutineType routineType,
        String alarmTime,
        boolean alarmEnabled,
        /** 미루기 시트에서 날짜 프리셋을 계산하는 데 쓴다 */
        int cycleDays,
        java.time.LocalDate nextDueAt,
        int totalPetCount,
        int completedPetCount,
        List<PetTodayStatus> petStatuses
) {
    private static final DateTimeFormatter HH_MM = DateTimeFormatter.ofPattern("HH:mm");

    public record PetTodayStatus(
            Long petId,
            String petName,
            String speciesName,
            String colorCode,
            String imageUrl,
            boolean completed,
            Long logId
    ) {}

    public static TodayRoutineResponse from(RoutineMst routine, List<PetTodayStatus> petStatuses) {
        int completedCount = (int) petStatuses.stream().filter(PetTodayStatus::completed).count();
        return new TodayRoutineResponse(
                routine.getId(),
                routine.getTitle(),
                routine.getRoutineType(),
                routine.getAlarmTime() != null ? routine.getAlarmTime().format(HH_MM) : null,
                routine.isAlarmEnabled(),
                routine.getCycleDays(),
                routine.getNextDueAt(),
                petStatuses.size(),
                completedCount,
                petStatuses
        );
    }
}
