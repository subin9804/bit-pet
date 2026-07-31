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
                @Index(name = "idx_nfc_tag_mst_pet",  columnList = "pet_id"),
                @Index(name = "idx_nfc_tag_mst_user", columnList = "user_id")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class NfcTagMst extends BaseTimeEntity {

    @Id
    @Column(name = "tag_cd", length = 10, updatable = false)
    private String tagCd;

    /** NULL = 미판매 재고 또는 연결 해제 상태 */
    @Column(name = "pet_id")
    private Long petId;

    /** 소유권. 남의 태그 탈취 방지용 */
    @Column(name = "user_id")
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "default_action_cd", nullable = false, length = 20)
    private TagActionCd defaultActionCd = TagActionCd.PET_DETAIL;

    /** 연결 시각. 해제해도 남겨 "한 번은 연결됐던 태그"를 구분한다. */
    @Column(name = "linked_at")
    private Instant linkedAt;

    @Column(name = "scan_cnt", nullable = false)
    private int scanCnt = 0;

    @Column(name = "last_scan_at")
    private Instant lastScanAt;

    /** 재고용 — 개체 연결 없이 태그 코드만 발급 */
    public static NfcTagMst stock(String tagCd) {
        NfcTagMst tag = new NfcTagMst();
        tag.tagCd = tagCd;
        tag.defaultActionCd = TagActionCd.PET_DETAIL;
        return tag;
    }

    public boolean isLinked() {
        return petId != null;
    }

    public boolean isOwnedBy(Long userId) {
        return this.userId != null && this.userId.equals(userId);
    }

    public void linkTo(Long petId, Long userId, TagActionCd actionCd) {
        this.petId = petId;
        this.userId = userId;
        this.defaultActionCd = actionCd != null ? actionCd : TagActionCd.PET_DETAIL;
        this.linkedAt = Instant.now();
    }

    /** 연결 해제 — 레코드는 남기고 연결만 끊는다 (태그 재사용 가능) */
    public void unlink() {
        this.petId = null;
        this.userId = null;
        this.defaultActionCd = TagActionCd.PET_DETAIL;
    }

    public void updateAction(TagActionCd actionCd) {
        if (actionCd != null) this.defaultActionCd = actionCd;
    }

    public void markScanned() {
        this.scanCnt++;
        this.lastScanAt = Instant.now();
    }
}
