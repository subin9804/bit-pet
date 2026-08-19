package io.bitpet.notification.domain;

public enum NotificationStatus {
    PENDING,
    SENT,
    FAILED,
    READ,
    /**
     * 수신 설정으로 푸시를 생략함. 앱 내 알림함에는 그대로 노출된다.
     *
     * <p>SENT 로 뭉뚱그리면 발송 통계가 거짓이 되고, FAILED 로 두면 장애 알람이 울린다.
     * 안 보낸 것은 성공도 실패도 아니다.
     */
    SKIPPED
}
