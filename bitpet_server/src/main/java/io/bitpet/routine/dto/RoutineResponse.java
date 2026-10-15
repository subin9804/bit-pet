package io.bitpet.routine.dto;

import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.domain.RoutineCycleMode;
import io.bitpet.routine.domain.RoutineType;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public record RoutineResponse(
        Long id,
        Long userId,
        RoutineType routineType,
        String title,
        int cycleDays,
        RoutineCycleMode cycleMode,
        /** ISO 요일 (1=월 … 7=일). WEEKDAY 가 아니면 빈 배열 */
        List<Integer> daysOfWeek,
        /** 1~31, 32=말일. MONTHDAY 가 아니면 빈 배열 */
        List<Integer> daysOfMonth,
        LocalTime alarmTime,
        boolean alarmEnabled,
        LocalDate startDate,
        LocalDate lastExecutedAt,
        LocalDate nextDueAt,
        boolean active,
        String memo,
        /** 마지막으로 미룬 시각 — null 이면 미룬 적 없음 */
        Instant postponedAt,
        /** 미루기 직전 예정일 — "9/16에서 미룸" 표시용 */
        LocalDate postponedFrom,
        List<Long> petIds,
        int petCount,
        Instant createdAt,
        Instant updatedAt
) {
    public static RoutineResponse from(RoutineMst r, List<Long> petIds) {
        return new RoutineResponse(
                r.getId(), r.getUserId(), r.getRoutineType(), r.getTitle(),
                r.getCycleDays(), r.getCycleMode(),
                List.copyOf(r.getCycleDaysOfWeek()), List.copyOf(r.getCycleDaysOfMonth()),
                r.getAlarmTime(), r.isAlarmEnabled(),
                r.getStartDate(), r.getLastExecutedAt(), r.getNextDueAt(),
                r.isActive(), r.getMemo(),
                r.getPostponedAt(), r.getPostponedFrom(),
                petIds, petIds.size(),
                r.getCreatedAt(), r.getUpdatedAt()
        );
    }

    public static RoutineResponse from(RoutineMst r) {
        return from(r, List.of());
    }
}
