package io.bitpet.common.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * FCM(Firebase Cloud Messaging) 설정.
 *
 * <p>{@code credentials-path}가 비어 있거나 파일이 없으면 FCM 발송은 자동으로 비활성화되고
 * 알림은 DB(notification_log_dtl)에만 기록된다. 로컬 개발에서 서비스 계정 키 없이 기동 가능.
 */
@ConfigurationProperties(prefix = "bitpet.fcm")
public record FcmProperties(
        boolean enabled,
        String credentialsPath,
        String projectId,
        String androidChannelId
) {
    public FcmProperties {
        if (androidChannelId == null || androidChannelId.isBlank()) {
            androidChannelId = "bitpet_default_channel";
        }
    }
}
