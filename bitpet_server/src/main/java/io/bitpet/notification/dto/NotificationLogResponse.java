package io.bitpet.notification.dto;

import io.bitpet.notification.domain.NotificationLogDtl;
import io.bitpet.notification.domain.NotificationStatus;
import io.bitpet.notification.domain.NotificationType;

import java.time.Instant;

/**
 * @param postId 알림함 '바로가기'가 열 게시글. 좋아요는 referenceId 그대로지만 댓글은 referenceId 가
 *               comment_id 라 앱이 글을 특정할 수 없어서 서버가 풀어 준다. 커뮤니티 알림이 아니면 null.
 */
public record NotificationLogResponse(
        Long id,
        NotificationType notificationType,
        Long petId,
        Long routineId,
        Long referenceId,
        Long postId,
        String title,
        String body,
        Instant sentAt,
        NotificationStatus status
) {
    public static NotificationLogResponse from(NotificationLogDtl log) {
        Long postId = log.getNotificationType() == NotificationType.COMMUNITY_LIKE
                ? log.getReferenceId() : null;
        return of(log, postId);
    }

    public static NotificationLogResponse of(NotificationLogDtl log, Long postId) {
        return new NotificationLogResponse(
                log.getId(),
                log.getNotificationType(),
                log.getPetId(),
                log.getRoutineId(),
                log.getReferenceId(),
                postId,
                log.getTitle(),
                log.getBody(),
                log.getSentAt(),
                log.getStatus()
        );
    }
}
