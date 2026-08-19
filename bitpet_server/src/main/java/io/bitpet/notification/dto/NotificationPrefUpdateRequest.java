package io.bitpet.notification.dto;

/**
 * 알림 설정 부분 수정. <b>전부 nullable 이고 null 은 "안 바꿈"이다.</b>
 *
 * <p>토글 하나를 눌렀을 때 그 항목만 보내면 되도록 한 것이다. 원시 boolean 이면
 * 빠진 필드가 false 로 도착해 누르지도 않은 알림이 꺼진다.
 *
 * <p>{@code system}은 받지 않는다. 끌 수 없는 항목의 요청 필드를 열어두면
 * 앱이 보낼 수 있게 되고, 서버가 조용히 무시하면 껐는데 계속 오는 것처럼 보인다.
 */
public record NotificationPrefUpdateRequest(
        Boolean routine,
        Boolean comment,
        Boolean postLike,
        Boolean marketing
) {
}
