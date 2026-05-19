package io.bitpet.notification.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "notification_log_dtl",
        indexes = {
                @Index(name = "idx_notification_log_user_time", columnList = "user_id, sent_at"),
                @Index(name = "idx_notification_log_status",    columnList = "status, sent_at")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class NotificationLogDtl extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "pet_id")
    private Long petId;

    @Column(name = "routine_id")
    private Long routineId;

    @Column(name = "template_code", length = 50)
    private String templateCode;

    @Column(nullable = false, length = 255)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String body;

    @Column(name = "sent_at", nullable = false)
    private Instant sentAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private NotificationStatus status;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    @Builder
    private NotificationLogDtl(Long userId, Long petId, Long routineId,
                                String templateCode, String title, String body,
                                Instant sentAt, NotificationStatus status) {
        this.userId       = userId;
        this.petId        = petId;
        this.routineId    = routineId;
        this.templateCode = templateCode;
        this.title        = title;
        this.body         = body;
        this.sentAt       = sentAt != null ? sentAt : Instant.now();
        this.status       = status != null ? status : NotificationStatus.PENDING;
    }

    public void markRead() {
        this.status = NotificationStatus.READ;
    }

    public void markFailed(String errorMessage) {
        this.status       = NotificationStatus.FAILED;
        this.errorMessage = errorMessage;
    }
}
