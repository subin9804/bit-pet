package io.bitpet.notification.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 알림 종류별 푸시 수신 설정. 유저당 1행.
 *
 * <p>행이 없으면 전부 켜진 상태다({@link #defaultsFor}). 가입 때 만들지 않고 처음
 * 끌 때 만든다 — 없는 상태와 기본값 상태가 같으면 기존 유저 백필이 필요 없다.
 *
 * <p>여기서 다루지 않는 것: {@code SYSTEM}(공지·점검)은 끌 수 없고,
 * {@code MARKETING}은 {@code user_agreement_dtl}이 관리한다(설정이 아니라 동의 기록).
 */
@Entity
@Table(name = "user_notification_pref")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserNotificationPref extends BaseTimeEntity {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "routine", nullable = false)
    private boolean routine = true;

    @Column(name = "comment", nullable = false)
    private boolean comment = true;

    /** like 는 SQL 예약어라 컬럼명을 피했다. */
    @Column(name = "post_like", nullable = false)
    private boolean postLike = true;

    private UserNotificationPref(Long userId) {
        this.userId = userId;
    }

    public static UserNotificationPref defaultsFor(Long userId) {
        return new UserNotificationPref(userId);
    }

    /**
     * 전달된 항목만 반영한다. null 은 "안 바꿈"이지 false 가 아니다 —
     * 토글 하나를 누른 요청이 나머지를 전부 꺼버리면 안 된다.
     */
    public void update(Boolean routine, Boolean comment, Boolean postLike) {
        if (routine != null) this.routine = routine;
        if (comment != null) this.comment = comment;
        if (postLike != null) this.postLike = postLike;
    }

    /**
     * 이 종류의 푸시를 보내도 되는지.
     *
     * <p>모르는 종류는 <b>보낸다</b>. 알림 종류를 새로 추가하면서 이 스위치를 빠뜨렸을 때,
     * 조용히 안 가는 것보다 가는 쪽이 눈에 띈다 — 안 오는 알림은 원인을 찾기 어렵다.
     */
    public boolean allows(NotificationType type) {
        return switch (type) {
            case ROUTINE_ALARM     -> routine;
            case COMMUNITY_COMMENT -> comment;
            case COMMUNITY_LIKE    -> postLike;
            default                -> true;
        };
    }
}
