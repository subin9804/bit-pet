package io.bitpet.routine.dto;

import io.bitpet.routine.domain.RoutineCycleMode;
import io.bitpet.routine.domain.RoutineType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.time.LocalTime;
import java.util.List;

public record RoutineCreateRequest(
        @NotNull RoutineType routineType,
        @NotBlank @Size(max = 100) String title,
        @Positive int cycleDays,
        LocalTime alarmTime,
        boolean alarmEnabled,
        List<Long> petIds,
        Instant startAt,
        String memo,
        /** 반복 방식. null 이면 INTERVAL (구버전 앱 호환) */
        RoutineCycleMode cycleMode,
        /** WEEKDAY 전용 — ISO 요일 (1=월 … 7=일) */
        List<Integer> daysOfWeek,
        /** MONTHDAY 전용 — 1~31, 32=말일 */
        List<Integer> daysOfMonth
) {}
