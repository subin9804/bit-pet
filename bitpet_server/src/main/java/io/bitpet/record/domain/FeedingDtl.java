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

    @Column(name = "routine_log_id")
    private Long routineLogId;

    /** 거식이면 null. {@link #refusedYn} 과 DB CHECK 로 묶여 있다. */
    @Column(name = "food_type", length = 50)
    private String foodType;

    /** 'Y' = 먹이를 거부한 기록 (먹이 종류·양 없이 메모만), 'N' = 일반 급여 */
    @Column(name = "refused_yn", nullable = false, length = 1)
    private String refusedYn = "N";

    @Column(precision = 6, scale = 2)
    private BigDecimal amount;

    @Column(length = 10)
    private String unit;

    @Column(name = "size_label", length = 10)
    private String sizeLabel;

    @Enumerated(EnumType.STRING)
    @Column(name = "supplement", length = 20)
    private FeedingSupplement supplement;

    @Column(name = "fed_at", nullable = false)
    private Instant fedAt;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "created_by_user_id")
    private Long createdByUserId;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private FeedingDtl(Long petId, Long routineId, Long routineLogId, String foodType, BigDecimal amount,
                       String unit, String sizeLabel, FeedingSupplement supplement,
                       Instant fedAt, String memo, Long createdByUserId, Boolean refused) {
        this.petId       = petId;
        this.routineId   = routineId;
        this.routineLogId = routineLogId;
        this.fedAt       = fedAt;
        this.memo        = memo;
        this.createdByUserId = createdByUserId;
        applyRefused(Boolean.TRUE.equals(refused), foodType, amount, unit, sizeLabel, supplement);
    }

    /**
     * 부분 수정. null 은 "그대로 두기"를 뜻한다 — 단 [refused] 가 넘어오면
     * 급여↔거식 전환이므로 먹이 관련 필드를 통째로 갈아끼운다.
     */
    public void update(String foodType, BigDecimal amount, String unit,
                       String sizeLabel, FeedingSupplement supplement,
                       Instant fedAt, String memo, Boolean refused) {
        if (fedAt != null) this.fedAt = fedAt;
        if (memo != null)  this.memo  = memo;

        if (refused != null) {
            applyRefused(refused, foodType, amount, unit, sizeLabel, supplement);
            return;
        }
        if (isRefused()) return; // 거식 기록에는 먹이 정보를 붙일 수 없다

        if (foodType != null)    this.foodType   = foodType;
        if (amount != null)      this.amount     = amount;
        if (unit != null)        this.unit       = unit;
        if (sizeLabel != null)   this.sizeLabel  = sizeLabel;
        if (supplement != null)  this.supplement = supplement;
    }

    public boolean isRefused() {
        return "Y".equals(refusedYn);
    }

    /**
     * 거식이면 먹이 관련 필드를 전부 비운다.
     * DB CHECK(ck_feeding_dtl_food_type_by_refused)와 같은 규칙을 엔티티에서도 지켜,
     * 어떤 경로로 저장해도 "거식인데 먹이가 남아 있는" 행이 생기지 않게 한다.
     */
    private void applyRefused(boolean refused, String foodType, BigDecimal amount,
                              String unit, String sizeLabel, FeedingSupplement supplement) {
        this.refusedYn = refused ? "Y" : "N";
        this.foodType   = refused ? null : foodType;
        this.amount     = refused ? null : amount;
        this.unit       = refused ? null : unit;
        this.sizeLabel  = refused ? null : sizeLabel;
        this.supplement = refused ? null : supplement;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
