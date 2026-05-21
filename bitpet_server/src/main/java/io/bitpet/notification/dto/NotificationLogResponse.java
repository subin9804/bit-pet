package io.bitpet.notification.dto;

import io.bitpet.notification.domain.NotificationLogDtl;
import io.bitpet.notification.domain.NotificationStatus;
import io.bitpet.notification.domain.NotificationType;

import java.time.Instant;

public record NotificationLogResponse(
        Long id,
        NotificationType notificationType,
        Long petId,
        Long routineId,
        Long referenceId,
        String title,
        String body,
        Instant sentAt,
        NotificationStatus status
) {
    public static NotificationLogResponse from(NotificationLogDtl log) {
        return new NotificationLogResponse(
                log.getId(),
                log.getNotificationType(),
                log.getPetId(),
                log.getRoutineId(),
                log.getReferenceId(),
                log.getTitle(),
                log.getBody(),
                log.getSentAt(),
                log.getStatus()
        );
    }
}
