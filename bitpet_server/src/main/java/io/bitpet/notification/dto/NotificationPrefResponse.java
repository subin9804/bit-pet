package io.bitpet.notification.dto;

import io.bitpet.notification.domain.UserNotificationPref;

/**
 * 알림 설정 화면이 그대로 그릴 수 있는 형태.
 *
 * <p>{@code system}·{@code marketing}이 함께 실리는 이유는 화면이 한 목록이기 때문이다.
 * 저장 위치는 셋 다 다르다 — 종류별 설정은 {@code user_notification_pref},
 * 공지는 아예 저장하지 않는 상수, 마케팅은 {@code user_agreement_dtl}의 동의 기록이다.
 *
 * @param system    항상 true. 끌 수 없다는 걸 앱이 알 수 있도록 값도 같이 내린다
 * @param marketing 마케팅 수신 동의 여부. 이 값을 바꾸면 동의 이력에 행이 하나 쌓인다
 */
public record NotificationPrefResponse(
        boolean routine,
        boolean comment,
        boolean postLike,
        boolean system,
        boolean marketing
) {
    public static NotificationPrefResponse of(UserNotificationPref pref, boolean marketing) {
        return new NotificationPrefResponse(
                pref.isRoutine(), pref.isComment(), pref.isPostLike(), true, marketing);
    }
}
