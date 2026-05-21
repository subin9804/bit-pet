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
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;

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
    private Instant lastExecutedAt;

    @Column(name = "next_due_at")
    private Instant nextDueAt;

    @Column(name = "is_active", nullable = false)
    private boolean active;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Builder
    private RoutineMst(Long userId, RoutineType routineType, String title,
                       int cycleDays, LocalTime alarmTime, boolean alarmEnabled,
                       Instant nextDueAt, String memo) {
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

    public void markExecuted(Instant at) {
        this.lastExecutedAt = at;
        this.nextDueAt      = at.plus(cycleDays, ChronoUnit.DAYS);
    }

    public void advanceNextDue(Instant from) {
        this.nextDueAt = from.plus(cycleDays, ChronoUnit.DAYS);
    }
}
