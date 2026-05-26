package io.bitpet.record.memo.repository;

import io.bitpet.record.memo.domain.MemoTagRls;
import io.bitpet.record.memo.domain.MemoTagRlsId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MemoTagRlsRepository extends JpaRepository<MemoTagRls, MemoTagRlsId> {

    List<MemoTagRls> findByMemoId(Long memoId);

    void deleteByMemoId(Long memoId);
}
