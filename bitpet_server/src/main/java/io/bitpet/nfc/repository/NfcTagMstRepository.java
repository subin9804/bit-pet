package io.bitpet.nfc.repository;

import io.bitpet.nfc.domain.NfcTagMst;
import io.bitpet.nfc.domain.TagStockStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NfcTagMstRepository extends JpaRepository<NfcTagMst, String> {

    List<NfcTagMst> findAllByUserIdOrderByLinkedAtDesc(Long userId);

    List<NfcTagMst> findAllByPetId(Long petId);

    /** 불량 회수 단위 조회 */
    List<NfcTagMst> findAllByBatchNo(String batchNo);

    /**
     * 재고 통계 — pet_id/linked_at 조합을 뒤지지 않고 status 하나로 센다.
     * STOCK=미판매 / SOLD=판매됐으나 미연결 / BOUND=연결됨 / REVOKED=차단
     */
    long countByStatus(TagStockStatus status);
}
