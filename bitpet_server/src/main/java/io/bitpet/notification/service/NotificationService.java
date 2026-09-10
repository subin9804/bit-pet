package io.bitpet.notification.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.notification.domain.NotificationLogDtl;
import io.bitpet.notification.domain.NotificationStatus;
import io.bitpet.notification.domain.NotificationType;
import io.bitpet.notification.dto.NotificationLogResponse;
import io.bitpet.notification.repository.NotificationLogDtlRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class NotificationService {

    private final NotificationLogDtlRepository notificationLogRepository;
    private final FcmSender fcmSender;
    private final NotificationPrefService notificationPrefService;
    private final DeviceTokenService deviceTokenService;

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

    /**
     * 알림 로그 저장 후 FCM 푸시 발송.
     * 푸시 실패가 알림 이력 자체를 롤백시키면 안 되므로 예외는 삼키고 status만 FAILED로 남긴다.
     * (FCM 비활성화·디바이스 토큰 없음은 실패가 아니라 SENT 유지 — 앱 내 알림함에는 그대로 노출)
     *
     * <p>알림 설정으로 꺼둔 종류는 <b>푸시만 건너뛰고 로그는 그대로 남긴다.</b> 사용자가 끈 것은
     * "폰이 울리는 것"이지 "무슨 일이 있었는지"가 아니다 — 알림함까지 비우면 루틴을 놓친 사실을
     * 나중에 확인할 방법이 없어진다. 발송을 안 했으므로 status 는 SENT 가 아니라 SKIPPED 다.
     */
    private void save(NotificationLogDtl notificationLog) {
        if (isUndeliverableRoutineAlarm(notificationLog)) {
            return;
        }
        notificationLogRepository.save(notificationLog);

        if (!notificationPrefService.allowsPush(
                notificationLog.getUserId(), notificationLog.getNotificationType())) {
            notificationLog.markSkipped();
            return;
        }

        try {
            fcmSender.send(notificationLog);
        } catch (Exception e) {
            log.warn("[FCM] 푸시 발송 중 예외 (userId={}): {}", notificationLog.getUserId(), e.getMessage());
            notificationLog.markFailed(e.getMessage());
        }
    }

    /**
     * 받을 기기가 없는 루틴 알람인가 — 맞으면 <b>행 자체를 만들지 않는다</b>.
     *
     * <p>알림 설정으로 끈 경우(SKIPPED)와 다르다. 그건 "폰이 울리는 것"만 끈 거라 앱을 열면
     * 알림함에서 볼 수 있어야 한다. 여기는 <b>볼 사람이 없는 경우</b>다 — 앱을 지운 계정에도
     * 루틴은 살아 있어서 스케줄러가 매일 행을 만들고, 그 행은 영원히 아무도 열지 않는다.
     *
     * <p>ROUTINE_ALARM 만 거르는 이유: 루틴 알람은 <b>그 시각에 알리는 것</b>이 전부라
     * 지나고 나면 가치가 없다. 반면 댓글·좋아요는 "내 글에 무슨 일이 있었나"의 기록이라
     * 나중에 재설치해서 열어봐도 읽을 값어치가 있다. SYSTEM(공지)도 같은 이유로 남긴다.
     *
     * <p>"마지막 로그인 N개월" 같은 임계값을 쓰지 않는 이유는 <b>추측이 필요 없어서</b>다.
     * 토큰이 0개라는 건 유추가 아니라 FCM 이 알려준 사실이다
     * ({@link DeviceTokenService#hasAnyDevice}).
     *
     * <p>⚠️ 로컬 개발에서 앱을 한 번도 안 띄웠다면 토큰이 없어 루틴 알람이 알림함에 안 쌓인다.
     * "알림이 왜 안 생기지"의 첫 번째 확인 대상이라 로그를 남긴다.
     */
    private boolean isUndeliverableRoutineAlarm(NotificationLogDtl notificationLog) {
        if (notificationLog.getNotificationType() != NotificationType.ROUTINE_ALARM) {
            return false;
        }
        if (deviceTokenService.hasAnyDevice(notificationLog.getUserId())) {
            return false;
        }
        log.debug("[알림] 등록된 기기가 없어 루틴 알람을 생성하지 않음 (userId={})",
                notificationLog.getUserId());
        return true;
    }
}
