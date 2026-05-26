package io.bitpet.record.laying.domain;

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

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "laying_hatch_dtl",
        indexes = {
                @Index(name = "idx_hatch_laying_status", columnList = "laying_id, status"),
                @Index(name = "idx_hatch_hatched_pet",   columnList = "hatched_pet_id")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class LayingHatchDtl extends BaseSyncEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "laying_id", nullable = false)
    private Long layingId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private HatchStatus status;

    @Column(name = "hatched_at")
    private Instant hatchedAt;

    @Column(name = "hatched_pet_id")
    private Long hatchedPetId;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private LayingHatchDtl(Long layingId, HatchStatus status, Instant hatchedAt, String memo) {
        this.layingId = layingId;
        this.status = status != null ? status : HatchStatus.PENDING;
        this.hatchedAt = hatchedAt;
        this.memo = memo;
    }

    public void update(HatchStatus status, Instant hatchedAt, Long hatchedPetId, String memo) {
        if (status != null)    this.status = status;
        this.hatchedAt = hatchedAt;
        this.hatchedPetId = hatchedPetId;
        this.memo = memo;
    }

    public void linkPet(Long petId) {
        this.hatchedPetId = petId;
        this.status = HatchStatus.HATCHED;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
