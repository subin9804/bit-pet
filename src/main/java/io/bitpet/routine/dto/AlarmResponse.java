package io.bitpet.routine.dto;

import io.bitpet.routine.domain.AlarmMst;

import java.time.Instant;
import java.time.LocalTime;

public record AlarmResponse(
        Long id,
        Long routineId,
        LocalTime alarmTime,
        boolean enabled,
        Instant createdAt,
        Instant updatedAt
) {
    public static AlarmResponse from(AlarmMst a) {
        return new AlarmResponse(
                a.getId(), a.getRoutineId(), a.getAlarmTime(),
                a.isEnabled(), a.getCreatedAt(), a.getUpdatedAt()
        );
    }
}
