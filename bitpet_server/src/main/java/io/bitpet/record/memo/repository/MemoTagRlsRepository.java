package io.bitpet.record.memo.repository;

import io.bitpet.record.memo.domain.MemoTagRls;
import io.bitpet.record.memo.domain.MemoTagRlsId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MemoTagRlsRepository extends JpaRepository<MemoTagRls, MemoTagRlsId> {

    List<MemoTagRls> findByMemoId(Long memoId);

    List<MemoTagRls> findByMemoIdIn(java.util.Collection<Long> memoIds);

    void deleteByMemoId(Long memoId);
}
