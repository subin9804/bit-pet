package io.bitpet.record.memo.repository;

import io.bitpet.record.memo.domain.MemoTagCd;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MemoTagCdRepository extends JpaRepository<MemoTagCd, Long> {

    List<MemoTagCd> findByIsActiveTrueOrderByDisplayOrderAsc();

    Optional<MemoTagCd> findByCode(String code);

    List<MemoTagCd> findByCodeIn(List<String> codes);
}
