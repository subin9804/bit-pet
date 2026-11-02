package io.bitpet.record.memo.repository;

import io.bitpet.record.memo.domain.MemoDtl;
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

    List<MemoDtl> findAllByPetIdOrderByLoggedAtDesc(Long petId);

    List<MemoDtl> findAllByPetIdInOrderByLoggedAtDesc(List<Long> petIds, Pageable pageable);

    /**
     * 하루치 조회 — **반열린 구간** [from, to). 파생 쿼리 `Between` 은 양끝을 포함해서
     * 다음날 00:00 정각 기록(날짜만 고르는 화면이 그 시각으로 저장한다)이 전날에도 잡혔다.
     */
    @Query("""
            SELECT m FROM MemoDtl m
            WHERE m.petId IN :petIds
              AND m.loggedAt >= :from AND m.loggedAt < :to
            ORDER BY m.loggedAt DESC
            """)
    List<MemoDtl> findDay(@Param("petIds") List<Long> petIds,
                          @Param("from") Instant from, @Param("to") Instant to);

    /** 루틴 로그에 연결된 메모 기록 (짝 정리·재로딩용) */
    List<MemoDtl> findByRoutineLogId(Long routineLogId);

    List<MemoDtl> findByRoutineLogIdIn(java.util.Collection<Long> routineLogIds);

    @Query("""
            SELECT DISTINCT m FROM MemoDtl m
            JOIN MemoTagRls r ON r.memoId = m.id
            JOIN MemoTagCd t  ON t.id = r.tagId
            WHERE m.petId = :petId
              AND t.code IN :tagCodes
            ORDER BY m.loggedAt DESC
            """)
    List<MemoDtl> findByPetIdAndTagCodes(
            @Param("petId") Long petId,
            @Param("tagCodes") List<String> tagCodes);

    @Query("""
            SELECT m FROM MemoDtl m
            WHERE m.petId = :petId
              AND m.loggedAt >= :from
              AND m.loggedAt <= :to
            ORDER BY m.loggedAt DESC
            """)
    List<MemoDtl> findByPetIdAndPeriod(
            @Param("petId") Long petId,
            @Param("from") Instant from,
            @Param("to") Instant to);
}
