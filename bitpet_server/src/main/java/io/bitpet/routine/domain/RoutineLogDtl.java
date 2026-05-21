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
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.Map;

@Entity
@Getter
@Table(
        name = "routine_log_dtl",
        indexes = {
                @Index(name = "idx_routine_log_dtl_routine_time", columnList = "routine_id, executed_at"),
                @Index(name = "idx_routine_log_dtl_pet_time",     columnList = "pet_id, executed_at")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RoutineLogDtl extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "routine_id", nullable = false)
    private Long routineId;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RoutineLogStatus status;

    @Column(name = "executed_at", nullable = false)
    private Instant executedAt;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "extra_data", columnDefinition = "jsonb")
    private Map<String, Object> extraData;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private RoutineLogDtl(Long routineId, Long petId, RoutineLogStatus status,
                          Instant executedAt, Map<String, Object> extraData, String memo) {
        this.routineId  = routineId;
        this.petId      = petId;
        this.status     = status != null ? status : RoutineLogStatus.COMPLETED;
        this.executedAt = executedAt != null ? executedAt : Instant.now();
        this.extraData  = extraData;
        this.memo       = memo;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
