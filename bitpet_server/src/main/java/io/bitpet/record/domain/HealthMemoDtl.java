package io.bitpet.record.domain;

import io.bitpet.common.entity.BaseSyncEntity;
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
import org.hibernate.annotations.SQLRestriction;

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "health_memo_dtl",
        indexes = @Index(name = "idx_health_memo_dtl_pet_time", columnList = "pet_id, recorded_at")
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class HealthMemoDtl extends BaseSyncEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Column(length = 100)
    private String symptom;

    @Column(columnDefinition = "TEXT")
    private String treatment;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private HealthMemoDtl(Long petId, String symptom, String treatment,
                          String memo, Instant recordedAt) {
        this.petId = petId;
        this.symptom = symptom;
        this.treatment = treatment;
        this.memo = memo;
        this.recordedAt = recordedAt;
    }

    public void update(String symptom, String treatment, String memo, Instant recordedAt) {
        if (symptom != null) this.symptom = symptom;
        if (treatment != null) this.treatment = treatment;
        if (memo != null) this.memo = memo;
        if (recordedAt != null) this.recordedAt = recordedAt;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
