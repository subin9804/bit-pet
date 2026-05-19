package io.bitpet.routine.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Entity
@Getter
@Table(
        name = "alarm_mst",
        indexes = @Index(name = "idx_alarm_mst_routine", columnList = "routine_id, is_enabled")
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class AlarmMst extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "routine_id", nullable = false)
    private Long routineId;

    @Column(name = "alarm_time", nullable = false, columnDefinition = "TIME")
    private LocalTime alarmTime;

    @Column(name = "is_enabled", nullable = false)
    private boolean enabled;

    @Builder
    private AlarmMst(Long routineId, LocalTime alarmTime, boolean enabled) {
        this.routineId = routineId;
        this.alarmTime = alarmTime;
        this.enabled   = enabled;
    }

    public void update(LocalTime alarmTime, boolean enabled) {
        this.alarmTime = alarmTime;
        this.enabled   = enabled;
    }
}
