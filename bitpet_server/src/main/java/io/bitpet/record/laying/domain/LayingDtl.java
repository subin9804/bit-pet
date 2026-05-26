package io.bitpet.record.laying.domain;

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

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Getter
@Table(
        name = "laying_dtl",
        indexes = {
                @Index(name = "idx_laying_dtl_pet_time", columnList = "pet_id, laid_at"),
                @Index(name = "idx_laying_dtl_mating",   columnList = "mating_id")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class LayingDtl extends BaseSyncEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Column(name = "mating_id")
    private Long matingId;

    @Column(name = "laid_at", nullable = false)
    private Instant laidAt;

    @Column(name = "egg_count_total", nullable = false)
    private int eggCountTotal;

    @Column(name = "egg_count_fertile")
    private Integer eggCountFertile;

    @Column(name = "incubation_temp", precision = 4, scale = 1)
    private BigDecimal incubationTemp;

    @Column(name = "incubation_humidity", precision = 4, scale = 1)
    private BigDecimal incubationHumidity;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private LayingDtl(Long petId, Long matingId, Instant laidAt, int eggCountTotal,
                      Integer eggCountFertile, BigDecimal incubationTemp,
                      BigDecimal incubationHumidity, String memo) {
        this.petId = petId;
        this.matingId = matingId;
        this.laidAt = laidAt;
        this.eggCountTotal = eggCountTotal;
        this.eggCountFertile = eggCountFertile;
        this.incubationTemp = incubationTemp;
        this.incubationHumidity = incubationHumidity;
        this.memo = memo;
    }

    public void update(Long matingId, Instant laidAt, int eggCountTotal,
                       Integer eggCountFertile, BigDecimal incubationTemp,
                       BigDecimal incubationHumidity, String memo) {
        this.matingId = matingId;
        if (laidAt != null) this.laidAt = laidAt;
        this.eggCountTotal = eggCountTotal;
        this.eggCountFertile = eggCountFertile;
        this.incubationTemp = incubationTemp;
        this.incubationHumidity = incubationHumidity;
        this.memo = memo;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
