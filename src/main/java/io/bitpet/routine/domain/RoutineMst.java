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
import java.time.temporal.ChronoUnit;

@Entity
@Getter
@Table(
        name = "routine_mst",
        indexes = {
                @Index(name = "idx_routine_mst_pet_active", columnList = "pet_id, is_active"),
                @Index(name = "idx_routine_mst_next_due",   columnList = "next_due_at")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RoutineMst extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Enumerated(EnumType.STRING)
    @Column(name = "routine_type", nullable = false, length = 20)
    private RoutineType routineType;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(name = "cycle_days", nullable = false)
    private int cycleDays;

    @Column(name = "last_executed_at")
    private Instant lastExecutedAt;

    @Column(name = "next_due_at")
    private Instant nextDueAt;

    @Column(name = "is_active", nullable = false)
    private boolean active;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Builder
    private RoutineMst(Long petId, RoutineType routineType, String title,
                       int cycleDays, Instant nextDueAt, String memo) {
        this.petId       = petId;
        this.routineType = routineType;
        this.title       = title;
        this.cycleDays   = cycleDays;
        this.nextDueAt   = nextDueAt;
        this.active      = true;
        this.memo        = memo;
    }

    public void update(RoutineType routineType, String title, int cycleDays,
                       Boolean active, String memo) {
        this.routineType = routineType;
        this.title       = title;
        this.cycleDays   = cycleDays;
        if (active != null) this.active = active;
        this.memo        = memo;
    }

    public void markExecuted(Instant at) {
        this.lastExecutedAt = at;
        this.nextDueAt      = at.plus(cycleDays, ChronoUnit.DAYS);
    }

    public void advanceNextDue(Instant from) {
        this.nextDueAt = from.plus(cycleDays, ChronoUnit.DAYS);
    }
}
