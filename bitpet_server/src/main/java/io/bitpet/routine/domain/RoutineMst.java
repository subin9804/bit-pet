package io.bitpet.routine.domain;

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
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;

@Entity
@Getter
@Table(
        name = "routine_mst",
        indexes = {
                @Index(name = "idx_routine_mst_user_active", columnList = "user_id, is_active"),
                @Index(name = "idx_routine_mst_next_due",    columnList = "next_due_at")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RoutineMst extends BaseTimeEntity {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "routine_type", nullable = false, length = 20)
    private RoutineType routineType;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(name = "cycle_days", nullable = false)
    private int cycleDays;

    @Column(name = "alarm_time", columnDefinition = "TIME")
    private LocalTime alarmTime;

    @Column(name = "is_alarm_enabled", nullable = false)
    private boolean alarmEnabled;

    @Column(name = "last_executed_at")
    private LocalDate lastExecutedAt;

    @Column(name = "next_due_at")
    private LocalDate nextDueAt;

    @Column(name = "is_active", nullable = false)
    private boolean active;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "last_notified_at")
    private Instant lastNotifiedAt;

    @Builder
    private RoutineMst(Long userId, RoutineType routineType, String title,
                       int cycleDays, LocalTime alarmTime, boolean alarmEnabled,
                       LocalDate nextDueAt, String memo) {
        this.userId       = userId;
        this.routineType  = routineType;
        this.title        = title;
        this.cycleDays    = cycleDays;
        this.alarmTime    = alarmTime;
        this.alarmEnabled = alarmEnabled;
        this.nextDueAt    = nextDueAt;
        this.active       = true;
        this.memo         = memo;
    }

    public void update(RoutineType routineType, String title, int cycleDays,
                       LocalTime alarmTime, boolean alarmEnabled,
                       Boolean active, String memo) {
        this.routineType  = routineType;
        this.title        = title;
        this.cycleDays    = cycleDays;
        this.alarmTime    = alarmTime;
        this.alarmEnabled = alarmEnabled;
        if (active != null) this.active = active;
        this.memo         = memo;
    }

    /** 루틴 완료 시 — lastExecutedAt 기록, nextDueAt을 다음 주기 날짜로 전진 */
    public void markExecuted(Instant at) {
        LocalDate completionDate = at.atZone(SEOUL).toLocalDate();
        this.lastExecutedAt = completionDate;
        this.nextDueAt      = completionDate.plusDays(cycleDays);
    }

    /** 알림 발송 기록 — nextDueAt은 변경하지 않음 */
    public void markNotified(Instant at) {
        this.lastNotifiedAt = at;
    }

    /** 예정일이 지난 미완료 루틴 — 다음 주기 날짜로 전진 (자정 배치용) */
    public void advanceDueDate() {
        if (nextDueAt == null) return;
        this.nextDueAt = nextDueAt.plusDays(cycleDays);
    }
}
