package io.bitpet.notification.dto;

import io.bitpet.notification.domain.NotificationLogDtl;
import io.bitpet.notification.domain.NotificationStatus;

import java.time.Instant;

public record NotificationLogResponse(
        Long id,
        Long petId,
        Long routineId,
        String title,
        String body,
        Instant sentAt,
        NotificationStatus status
) {
    public static NotificationLogResponse from(NotificationLogDtl log) {
        return new NotificationLogResponse(
                log.getId(), log.getPetId(), log.getRoutineId(),
                log.getTitle(), log.getBody(), log.getSentAt(), log.getStatus()
        );
    }
}
