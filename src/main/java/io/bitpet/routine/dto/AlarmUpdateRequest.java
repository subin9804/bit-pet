package io.bitpet.routine.dto;

import jakarta.validation.constraints.NotNull;

import java.time.LocalTime;

public record AlarmUpdateRequest(
        @NotNull LocalTime alarmTime,
        boolean enabled
) {}
