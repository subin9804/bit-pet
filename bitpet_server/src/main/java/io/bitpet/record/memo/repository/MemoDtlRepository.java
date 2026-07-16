package io.bitpet.record.memo.repository;

import io.bitpet.record.memo.domain.MemoDtl;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MemoDtlRepository extends JpaRepository<MemoDtl, Long> {

    Optional<MemoDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);

    Page<MemoDtl> findAllByPetIdOrderByLoggedAtDesc(Long petId, Pageable pageable);

    List<MemoDtl> findAllByPetIdInOrderByLoggedAtDesc(List<Long> petIds, Pageable pageable);

    List<MemoDtl> findAllByPetIdInAndLoggedAtBetweenOrderByLoggedAtDesc(
            List<Long> petIds, Instant from, Instant to);

    /** 루틴 완료로 생성된 메모 기록 조회 (완료 취소·재저장 시 짝 정리용) */
    List<MemoDtl> findAllByRoutineIdAndPetIdAndLoggedAt(
            Long routineId, Long petId, Instant loggedAt);

    @Query("""
            SELECT DISTINCT m FROM MemoDtl m
            JOIN MemoTagRls r ON r.memoId = m.id
            JOIN MemoTagCd t  ON t.id = r.tagId
            WHERE m.petId = :petId
              AND t.code IN :tagCodes
            ORDER BY m.loggedAt DESC
            """)
    Page<MemoDtl> findByPetIdAndTagCodes(
            @Param("petId") Long petId,
            @Param("tagCodes") List<String> tagCodes,
            Pageable pageable);

    @Query("""
            SELECT m FROM MemoDtl m
            WHERE m.petId = :petId
              AND m.loggedAt >= :from
              AND m.loggedAt <= :to
            ORDER BY m.loggedAt DESC
            """)
    Page<MemoDtl> findByPetIdAndPeriod(
            @Param("petId") Long petId,
            @Param("from") Instant from,
            @Param("to") Instant to,
            Pageable pageable);
}
