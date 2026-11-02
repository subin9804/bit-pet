package io.bitpet.record.repository;

import io.bitpet.record.domain.FeedingDtl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FeedingDtlRepository extends JpaRepository<FeedingDtl, Long> {

    List<FeedingDtl> findAllByPetIdOrderByFedAtDesc(Long petId);

    List<FeedingDtl> findAllByPetIdInOrderByFedAtDesc(Collection<Long> petIds, Pageable pageable);

    /** 하루치 조회 — 반열린 구간 [from, to). 양끝 포함 `Between` 은 다음날 00:00 기록을 전날에도 잡는다. */
    @org.springframework.data.jpa.repository.Query("""
            SELECT x FROM FeedingDtl x
            WHERE x.petId IN :petIds AND x.fedAt >= :from AND x.fedAt < :to
            ORDER BY x.fedAt DESC
            """)
    List<FeedingDtl> findDay(
            @org.springframework.data.repository.query.Param("petIds") Collection<Long> petIds,
            @org.springframework.data.repository.query.Param("from") java.time.Instant from,
            @org.springframework.data.repository.query.Param("to") java.time.Instant to);

    /** 루틴 완료 로그에 연결된 급여 기록 (짝 정리·재로딩용) */
    List<FeedingDtl> findByRoutineLogId(Long routineLogId);

    List<FeedingDtl> findByRoutineLogIdIn(Collection<Long> routineLogIds);

    Optional<FeedingDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);
}
