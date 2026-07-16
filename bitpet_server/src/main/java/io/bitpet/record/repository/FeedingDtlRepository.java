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

    /** 루틴 완료로 생성된 급여 기록 조회 (완료 취소·재저장 시 짝 정리용) */
    List<FeedingDtl> findAllByRoutineIdAndPetIdAndFedAt(
            Long routineId, Long petId, java.time.Instant fedAt);

    Optional<FeedingDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);
}
