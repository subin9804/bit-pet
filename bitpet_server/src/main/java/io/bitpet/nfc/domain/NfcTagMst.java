package io.bitpet.nfc.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * NFC 태그 이름표.
 *
 * <p>태그 자체는 {@code tag_cd} 하나만 가지고 출고되며, 어떤 개체에 붙을지는 출고 시점에 정해지지 않는다.
 * 유저가 스캔 후 앱에서 직접 연결하고, 그 연결 정보는 오직 이 테이블에만 존재한다.
 */
@Entity
@Getter
@Table(
        name = "nfc_tag_mst",
        indexes = {
                @Index(name = "idx_nfc_tag_mst_pet",    columnList = "pet_id"),
                @Index(name = "idx_nfc_tag_mst_user",   columnList = "user_id"),
                @Index(name = "idx_nfc_tag_mst_status", columnList = "status")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class NfcTagMst extends BaseTimeEntity {

    /** 현재 입고분. 세대가 바뀌면 발급 시점에 넘겨서 덮어쓴다 */
    public static final String DEFAULT_CHIP_TYPE = "NTAG203";

    @Id
    @Column(name = "tag_cd", length = 10, updatable = false)
    private String tagCd;

    /** 칩 세대. NTAG203 은 패스워드 보호가 불가능해 락 미적용으로 출고된다 */
    @Column(name = "chip_type", nullable = false, length = 20)
    private String chipType = DEFAULT_CHIP_TYPE;

    /** 생산 배치. 불량 회수 단위 — 구재고는 NULL */
    @Column(name = "batch_no", length = 20)
    private String batchNo;

    /** 태그 자체의 생애주기. 스캔한 사람 기준 판정과는 별개다 */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private TagStockStatus status = TagStockStatus.STOCK;

    /** NULL = 미판매 재고 또는 연결 해제 상태 */
    @Column(name = "pet_id")
    private Long petId;

    /** 소유권. 남의 태그 탈취 방지용 */
    @Column(name = "user_id")
    private Long userId;

    /** 연결 시각. 해제해도 남겨 "한 번은 연결됐던 태그"를 구분한다. */
    @Column(name = "linked_at")
    private Instant linkedAt;

    /** 재고용 — 개체 연결 없이 태그 코드만 발급 */
    public static NfcTagMst stock(String tagCd, String chipType, String batchNo) {
        NfcTagMst tag = new NfcTagMst();
        tag.tagCd = tagCd;
        tag.chipType = (chipType == null || chipType.isBlank()) ? DEFAULT_CHIP_TYPE : chipType;
        tag.batchNo = (batchNo == null || batchNo.isBlank()) ? null : batchNo;
        tag.status = TagStockStatus.STOCK;
        return tag;
    }

    public boolean isLinked() {
        return petId != null;
    }

    /** 차단된 태그 — 연결도 조회도 되살아나지 않는다 */
    public boolean isRevoked() {
        return status == TagStockStatus.REVOKED;
    }

    public boolean isOwnedBy(Long userId) {
        return this.userId != null && this.userId.equals(userId);
    }

    public void linkTo(Long petId, Long userId) {
        this.petId = petId;
        this.userId = userId;
        this.linkedAt = Instant.now();
        this.status = TagStockStatus.BOUND;
    }

    /**
     * 연결 해제 — 레코드는 남기고 연결만 끊는다 (태그 재사용 가능).
     * 재고(STOCK)로 되돌리지 않는다. 이미 유저 손에 넘어간 태그다.
     */
    public void unlink() {
        this.petId = null;
        this.userId = null;
        this.status = TagStockStatus.SOLD;
    }

    /** 분실·복제 사고 — 되돌리는 경로는 두지 않는다 */
    public void revoke() {
        this.petId = null;
        this.userId = null;
        this.status = TagStockStatus.REVOKED;
    }
}
