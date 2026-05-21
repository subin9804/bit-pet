package io.bitpet.routine.dto;

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
        String memo
) {}
