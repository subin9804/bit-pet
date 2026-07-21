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

    List<FeedingDtl> findAllByPetIdInAndFedAtBetweenOrderByFedAtDesc(
            Collection<Long> petIds, java.time.Instant from, java.time.Instant to);

    /** 루틴 완료 로그에 연결된 급여 기록 (짝 정리·재로딩용) */
    List<FeedingDtl> findByRoutineLogId(Long routineLogId);

    List<FeedingDtl> findByRoutineLogIdIn(Collection<Long> routineLogIds);

    Optional<FeedingDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);
}
