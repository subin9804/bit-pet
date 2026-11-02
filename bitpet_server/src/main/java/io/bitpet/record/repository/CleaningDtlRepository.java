package io.bitpet.record.repository;

import io.bitpet.record.domain.CleaningDtl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CleaningDtlRepository extends JpaRepository<CleaningDtl, Long> {

    List<CleaningDtl> findAllByPetIdOrderByCleanedAtDesc(Long petId);

    List<CleaningDtl> findAllByPetIdInOrderByCleanedAtDesc(Collection<Long> petIds, Pageable pageable);

    /** 하루치 조회 — 반열린 구간 [from, to). 양끝 포함 `Between` 은 다음날 00:00 기록을 전날에도 잡는다. */
    @org.springframework.data.jpa.repository.Query("""
            SELECT x FROM CleaningDtl x
            WHERE x.petId IN :petIds AND x.cleanedAt >= :from AND x.cleanedAt < :to
            ORDER BY x.cleanedAt DESC
            """)
    List<CleaningDtl> findDay(
            @org.springframework.data.repository.query.Param("petIds") Collection<Long> petIds,
            @org.springframework.data.repository.query.Param("from") java.time.Instant from,
            @org.springframework.data.repository.query.Param("to") java.time.Instant to);

    /** 루틴 완료 로그에 연결된 청소 기록 (짝 정리·재로딩용) */
    List<CleaningDtl> findByRoutineLogId(Long routineLogId);

    List<CleaningDtl> findByRoutineLogIdIn(Collection<Long> routineLogIds);

    Optional<CleaningDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);
}
