package io.bitpet.nfc.repository;

import io.bitpet.nfc.domain.NfcTagBindHst;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * 태그 연결 이력. <b>쓰기는 append 만</b> — 수정·삭제 메서드를 추가하지 않는다.
 */
public interface NfcTagBindHstRepository extends JpaRepository<NfcTagBindHst, Long> {

    /** 태그 하나의 연결 내역 (최신순) — 분쟁 확인용 */
    List<NfcTagBindHst> findAllByTagCdOrderByIdDesc(String tagCd);
}
