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

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "cleaning_dtl",
        indexes = @Index(name = "idx_cleaning_dtl_pet_time", columnList = "pet_id, cleaned_at")
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CleaningDtl extends BaseSyncEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Enumerated(EnumType.STRING)
    @Column(name = "cleaning_type", nullable = false, length = 20)
    private CleaningType cleaningType;

    @Column(name = "cleaned_at", nullable = false)
    private Instant cleanedAt;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private CleaningDtl(Long petId, CleaningType cleaningType, Instant cleanedAt, String memo) {
        this.petId = petId;
        this.cleaningType = cleaningType;
        this.cleanedAt = cleanedAt;
        this.memo = memo;
    }

    public void update(CleaningType cleaningType, Instant cleanedAt, String memo) {
        if (cleaningType != null) this.cleaningType = cleaningType;
        if (cleanedAt != null) this.cleanedAt = cleanedAt;
        if (memo != null) this.memo = memo;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
