package io.bitpet.notification.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.notification.domain.NotificationLogDtl;
import io.bitpet.notification.domain.NotificationStatus;
import io.bitpet.notification.domain.NotificationType;
import io.bitpet.notification.dto.NotificationLogResponse;
import io.bitpet.notification.repository.NotificationLogDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class NotificationService {

    private final NotificationLogDtlRepository notificationLogRepository;

    public List<NotificationLogResponse> listNotifications(Long userId) {
        return notificationLogRepository.findTop50ByUserIdOrderBySentAtDesc(userId)
                .stream().map(NotificationLogResponse::from).toList();
    }

    @Transactional
    public NotificationLogResponse markRead(Long userId, Long notificationId) {
        NotificationLogDtl log = notificationLogRepository.findById(notificationId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOTIFICATION_NOT_FOUND));
        if (!log.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        log.markRead();
        return NotificationLogResponse.from(log);
    }

    // -------------------------------------------------------------------------
    // 루틴 알람 (RoutineScheduler에서 호출)
    // -------------------------------------------------------------------------

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void createRoutineNotification(Long userId, Long representativePetId, Long routineId,
                                          int petCount, String title, String body) {
        save(NotificationLogDtl.builder()
                .userId(userId)
                .petId(representativePetId)
                .routineId(routineId)
                .petCount(petCount)
                .notificationType(NotificationType.ROUTINE_ALARM)
                .title(title)
                .body(body)
                .status(NotificationStatus.SENT)
                .build());
    }

    // -------------------------------------------------------------------------
    // 커뮤니티 — 댓글 (PostCommentService에서 호출)
    // referenceId = comment_id
    // -------------------------------------------------------------------------

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void createCommentNotification(Long userId, Long commentId, String title, String body) {
        save(NotificationLogDtl.builder()
                .userId(userId)
                .referenceId(commentId)
                .notificationType(NotificationType.COMMUNITY_COMMENT)
                .title(title)
                .body(body)
                .status(NotificationStatus.SENT)
                .build());
    }

    // -------------------------------------------------------------------------
    // 커뮤니티 — 좋아요 (PostLikeService에서 호출)
    // referenceId = post_id
    // -------------------------------------------------------------------------

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void createLikeNotification(Long userId, Long postId, String title, String body) {
        save(NotificationLogDtl.builder()
                .userId(userId)
                .referenceId(postId)
                .notificationType(NotificationType.COMMUNITY_LIKE)
                .title(title)
                .body(body)
                .status(NotificationStatus.SENT)
                .build());
    }

    // -------------------------------------------------------------------------
    // AI 컨설팅 완료 (2차 도입 예정)
    // referenceId = pet_id
    // -------------------------------------------------------------------------

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void createAiConsultingNotification(Long userId, Long petId, String title, String body) {
        save(NotificationLogDtl.builder()
                .userId(userId)
                .petId(petId)
                .referenceId(petId)
                .notificationType(NotificationType.AI_CONSULTING)
                .title(title)
                .body(body)
                .status(NotificationStatus.SENT)
                .build());
    }

    // -------------------------------------------------------------------------
    // 시스템 공지·점검 알림
    // -------------------------------------------------------------------------

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void createSystemNotification(Long userId, String title, String body) {
        save(NotificationLogDtl.builder()
                .userId(userId)
                .notificationType(NotificationType.SYSTEM)
                .title(title)
                .body(body)
                .status(NotificationStatus.SENT)
                .build());
    }

    // -------------------------------------------------------------------------
    // internal
    // -------------------------------------------------------------------------

    private void save(NotificationLogDtl log) {
        notificationLogRepository.save(log);
        // TODO: FCM 실제 발송 연동 (firebase-admin SDK, 2차)
    }
}
