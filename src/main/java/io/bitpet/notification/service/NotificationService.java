package io.bitpet.notification.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.notification.domain.NotificationLogDtl;
import io.bitpet.notification.domain.NotificationStatus;
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

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void createRoutineNotification(Long userId, Long petId, Long routineId,
                                           String title, String body) {
        NotificationLogDtl log = NotificationLogDtl.builder()
                .userId(userId)
                .petId(petId)
                .routineId(routineId)
                .title(title)
                .body(body)
                .sentAt(Instant.now())
                .status(NotificationStatus.SENT)
                .build();
        notificationLogRepository.save(log);
    }
}
