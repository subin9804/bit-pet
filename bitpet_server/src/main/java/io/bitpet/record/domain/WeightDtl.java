package io.bitpet.record.domain;

import io.bitpet.common.entity.BaseSyncEntity;
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
import org.hibernate.annotations.SQLRestriction;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Getter
@Table(
        name = "weight_dtl",
        indexes = @Index(name = "idx_weight_dtl_pet_time", columnList = "pet_id, measured_at")
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class WeightDtl extends BaseSyncEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Column(name = "weight_g", nullable = false, precision = 8, scale = 2)
    private BigDecimal weightG;

    @Column(name = "measured_at", nullable = false)
    private Instant measuredAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private WeightSource source;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private WeightDtl(Long petId, BigDecimal weightG, Instant measuredAt,
                      WeightSource source, String memo) {
        this.petId = petId;
        this.weightG = weightG;
        this.measuredAt = measuredAt;
        this.source = source != null ? source : WeightSource.MANUAL;
        this.memo = memo;
    }

    public void update(BigDecimal weightG, Instant measuredAt, WeightSource source, String memo) {
        if (weightG != null)    this.weightG = weightG;
        if (measuredAt != null) this.measuredAt = measuredAt;
        if (source != null)     this.source = source;
        if (memo != null)       this.memo = memo;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
