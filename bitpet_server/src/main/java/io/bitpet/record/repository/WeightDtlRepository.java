package io.bitpet.record.repository;

import io.bitpet.record.domain.WeightDtl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface WeightDtlRepository extends JpaRepository<WeightDtl, Long> {

    List<WeightDtl> findAllByPetIdOrderByMeasuredAtDesc(Long petId);

    List<WeightDtl> findAllByPetIdInOrderByMeasuredAtDesc(Collection<Long> petIds, Pageable pageable);

    List<WeightDtl> findAllByPetIdInAndMeasuredAtBetweenOrderByMeasuredAtDesc(
            Collection<Long> petIds, java.time.Instant from, java.time.Instant to);

    /** 루틴 완료로 생성된 체중 기록 조회 (완료 취소·재저장 시 짝 정리용) */
    List<WeightDtl> findAllByRoutineIdAndPetIdAndMeasuredAt(
            Long routineId, Long petId, java.time.Instant measuredAt);

    Optional<WeightDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);
}
