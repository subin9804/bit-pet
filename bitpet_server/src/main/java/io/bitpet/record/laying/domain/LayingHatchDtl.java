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

    /** 클러치 안에서의 알 번호 (1부터). 화면은 이 번호로 알 칸을 그리고 "3번 알"로 부른다 */
    @Column(name = "egg_index")
    private Integer eggIndex;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private HatchStatus status;

    @Column(name = "hatched_at")
    private Instant hatchedAt;

    @Column(name = "hatched_pet_id")
    private Long hatchedPetId;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "created_by_user_id")
    private Long createdByUserId;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private LayingHatchDtl(Long layingId, Integer eggIndex, HatchStatus status, Instant hatchedAt,
                           String memo, Long createdByUserId) {
        this.layingId = layingId;
        this.eggIndex = eggIndex;
        this.status = status != null ? status : HatchStatus.PENDING;
        this.hatchedAt = hatchedAt;
        this.memo = memo;
        this.createdByUserId = createdByUserId;
    }

    public void update(HatchStatus status, Instant hatchedAt, Long hatchedPetId, String memo) {
        if (status != null)    this.status = status;
        this.hatchedAt = hatchedAt;
        this.hatchedPetId = hatchedPetId;
        this.memo = memo;
    }

    /**
     * 알 칸을 누를 때마다 대기 → 부화 → 무정 → 대기 로 돌린다. 부화일은 누른 날로 자동 기록한다.
     * (개체까지 등록된 알은 상태와 실제 개체가 어긋나므로 service 쪽에서 순환을 막는다)
     */
    public HatchStatus cycleStatus(Instant now) {
        HatchStatus next = switch (this.status) {
            case PENDING -> HatchStatus.HATCHED;
            case HATCHED -> HatchStatus.SLUG;
            default      -> HatchStatus.PENDING;   // SLUG·FAILED 모두 한 번 더 누르면 대기로
        };
        this.status = next;
        this.hatchedAt = next == HatchStatus.HATCHED ? now : null;
        return next;
    }

    /**
     * 등록해 둔 개체가 사라졌다 — 연결만 끊고 상태는 HATCHED 로 남긴다.
     *
     * <p>부화는 실제로 일어난 일이라 개체를 지운 것과 별개다. 상태까지 PENDING 으로
     * 되돌리면 "부화한 적 없는 알"이 되어 기록이 거짓이 된다. 연결이 끊긴 뒤에는
     * 알 칸을 다시 눌러 순환시킬 수 있으므로, 되돌리고 싶으면 사용자가 누르면 된다.
     */
    public void unlinkPet() {
        this.hatchedPetId = null;
    }

    public void linkPet(Long petId) {
        this.hatchedPetId = petId;
        this.status = HatchStatus.HATCHED;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
