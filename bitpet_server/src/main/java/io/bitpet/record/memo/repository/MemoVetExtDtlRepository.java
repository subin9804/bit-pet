package io.bitpet.record.memo.repository;

import io.bitpet.record.memo.domain.MemoVetExtDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MemoVetExtDtlRepository extends JpaRepository<MemoVetExtDtl, Long> {

    Optional<MemoVetExtDtl> findByMemoId(Long memoId);

    void deleteByMemoId(Long memoId);
}
