package io.bitpet.notification.service;

import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.ApnsConfig;
import com.google.firebase.messaging.Aps;
import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.Notification;
import com.google.firebase.messaging.SendResponse;
import io.bitpet.common.config.FcmProperties;
import io.bitpet.notification.domain.NotificationLogDtl;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * FCM 푸시 발송.
 *
 * <p>{@link FirebaseMessaging} 빈이 없으면(= 서비스 계정 키 미설정) 발송을 건너뛴다.
 * 알림 자체는 항상 notification_log_dtl 에 남으므로 앱 내 알림함은 정상 동작한다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class FcmSender {

    private final ObjectProvider<FirebaseMessaging> firebaseMessagingProvider;
    private final DeviceTokenService deviceTokenService;
    private final FcmProperties fcmProperties;

    /**
     * 알림 로그 1건을 해당 유저의 모든 디바이스로 발송.
     *
     * @return 발송 성공 건수. 비활성화·토큰 없음·실패 시 0
     */
    public int send(NotificationLogDtl notificationLog) {
        FirebaseMessaging messaging = firebaseMessagingProvider.getIfAvailable();
        if (messaging == null) {
            return 0;
        }

        List<String> tokens = deviceTokenService.findTokensByUser(notificationLog.getUserId());
        if (tokens.isEmpty()) {
            return 0;
        }

        MulticastMessage message = MulticastMessage.builder()
                .addAllTokens(tokens)
                .setNotification(Notification.builder()
                        .setTitle(notificationLog.getTitle())
                        .setBody(notificationLog.getBody())
                        .build())
                .putAllData(buildData(notificationLog))
                .setAndroidConfig(AndroidConfig.builder()
                        .setPriority(AndroidConfig.Priority.HIGH)
                        .setNotification(AndroidNotification.builder()
                                .setChannelId(fcmProperties.androidChannelId())
                                .setClickAction("FLUTTER_NOTIFICATION_CLICK")
                                .build())
                        .build())
                .setApnsConfig(ApnsConfig.builder()
                        .setAps(Aps.builder().setSound("default").build())
                        .build())
                .build();

        try {
            BatchResponse response = messaging.sendEachForMulticast(message);
            cleanUpInvalidTokens(tokens, response);
            return response.getSuccessCount();
        } catch (FirebaseMessagingException e) {
            log.warn("[FCM] 발송 실패 (userId={}, notificationId={}): {}",
                    notificationLog.getUserId(), notificationLog.getId(), e.getMessage());
            return 0;
        }
    }

    /** 앱이 알림을 탭했을 때 어디로 보낼지 판단할 수 있도록 타입·참조 ID 를 data 로 함께 전달 */
    private Map<String, String> buildData(NotificationLogDtl notificationLog) {
        Map<String, String> data = new HashMap<>();
        data.put("notificationId", String.valueOf(notificationLog.getId()));
        data.put("type", notificationLog.getNotificationType().name());
        putIfNotNull(data, "petId", notificationLog.getPetId());
        putIfNotNull(data, "routineId", notificationLog.getRoutineId());
        putIfNotNull(data, "referenceId", notificationLog.getReferenceId());
        putIfNotNull(data, "petCount", notificationLog.getPetCount());
        return data;
    }

    private void putIfNotNull(Map<String, String> data, String key, Object value) {
        if (value != null) {
            data.put(key, String.valueOf(value));
        }
    }

    /** UNREGISTERED / INVALID_ARGUMENT 응답 토큰은 더 이상 유효하지 않으므로 삭제 */
    private void cleanUpInvalidTokens(List<String> tokens, BatchResponse response) {
        List<SendResponse> responses = response.getResponses();
        List<String> invalid = new ArrayList<>();

        for (int i = 0; i < responses.size(); i++) {
            SendResponse each = responses.get(i);
            if (each.isSuccessful()) {
                continue;
            }
            FirebaseMessagingException error = each.getException();
            MessagingErrorCode code = error != null ? error.getMessagingErrorCode() : null;
            if (code == MessagingErrorCode.UNREGISTERED || code == MessagingErrorCode.INVALID_ARGUMENT) {
                invalid.add(tokens.get(i));
            }
        }

        deviceTokenService.deleteInvalidTokens(invalid);
    }
}
