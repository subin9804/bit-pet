package io.bitpet.nfc.repository;

import io.bitpet.nfc.domain.NfcTagMst;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface NfcTagMstRepository extends JpaRepository<NfcTagMst, String> {

    List<NfcTagMst> findAllByUserIdOrderByLinkedAtDesc(Long userId);

    List<NfcTagMst> findAllByPetId(Long petId);

    /** 미판매 재고 수 */
    @Query("SELECT COUNT(t) FROM NfcTagMst t WHERE t.petId IS NULL AND t.linkedAt IS NULL")
    long countUnsoldStock();

    /** 한 번 연결됐다가 지금은 해제된 태그 수 — 온보딩·양도 이탈 모니터링 */
    @Query("SELECT COUNT(t) FROM NfcTagMst t WHERE t.petId IS NULL AND t.linkedAt IS NOT NULL")
    long countReleased();

    @Query("SELECT COUNT(t) FROM NfcTagMst t WHERE t.petId IS NOT NULL")
    long countLinked();
}
