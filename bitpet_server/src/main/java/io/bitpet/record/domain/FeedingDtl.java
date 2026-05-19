package io.bitpet.record.domain;

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
import org.hibernate.annotations.SQLRestriction;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Getter
@Table(
        name = "feeding_dtl",
        indexes = @Index(name = "idx_feeding_dtl_pet_time", columnList = "pet_id, fed_at")
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class FeedingDtl extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Column(name = "food_type", nullable = false, length = 50)
    private String foodType;

    @Column(precision = 6, scale = 2)
    private BigDecimal amount;

    @Column(length = 10)
    private String unit;

    @Column(name = "fed_at", nullable = false)
    private Instant fedAt;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private FeedingDtl(Long petId, String foodType, BigDecimal amount,
                       String unit, Instant fedAt, String memo) {
        this.petId = petId;
        this.foodType = foodType;
        this.amount = amount;
        this.unit = unit;
        this.fedAt = fedAt;
        this.memo = memo;
    }

    public void update(String foodType, BigDecimal amount, String unit, Instant fedAt, String memo) {
        if (foodType != null) this.foodType = foodType;
        if (amount != null) this.amount = amount;
        if (unit != null) this.unit = unit;
        if (fedAt != null) this.fedAt = fedAt;
        if (memo != null) this.memo = memo;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
