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
        name = "feeding_dtl",
        indexes = {
                @Index(name = "idx_feeding_dtl_pet_time",  columnList = "pet_id, fed_at"),
                @Index(name = "idx_feeding_dtl_routine",   columnList = "routine_id, fed_at")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class FeedingDtl extends BaseSyncEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Column(name = "routine_id")
    private Long routineId;

    @Column(name = "food_type", nullable = false, length = 50)
    private String foodType;

    @Column(precision = 6, scale = 2)
    private BigDecimal amount;

    @Column(length = 10)
    private String unit;

    @Enumerated(EnumType.STRING)
    @Column(name = "feed_response", length = 20)
    private FeedResponse feedResponse;

    @Column(name = "fed_at", nullable = false)
    private Instant fedAt;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private FeedingDtl(Long petId, Long routineId, String foodType, BigDecimal amount,
                       String unit, FeedResponse feedResponse, Instant fedAt, String memo) {
        this.petId        = petId;
        this.routineId    = routineId;
        this.foodType     = foodType;
        this.amount       = amount;
        this.unit         = unit;
        this.feedResponse = feedResponse;
        this.fedAt        = fedAt;
        this.memo         = memo;
    }

    public void update(String foodType, BigDecimal amount, String unit,
                       FeedResponse feedResponse, Instant fedAt, String memo) {
        if (foodType != null)     this.foodType     = foodType;
        if (amount != null)       this.amount       = amount;
        if (unit != null)         this.unit         = unit;
        if (feedResponse != null) this.feedResponse = feedResponse;
        if (fedAt != null)        this.fedAt        = fedAt;
        if (memo != null)         this.memo         = memo;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
