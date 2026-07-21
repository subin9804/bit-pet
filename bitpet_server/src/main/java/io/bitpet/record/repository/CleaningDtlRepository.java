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

    List<CleaningDtl> findAllByPetIdInAndCleanedAtBetweenOrderByCleanedAtDesc(
            Collection<Long> petIds, java.time.Instant from, java.time.Instant to);

    /** 루틴 완료 로그에 연결된 청소 기록 (짝 정리·재로딩용) */
    List<CleaningDtl> findByRoutineLogId(Long routineLogId);

    List<CleaningDtl> findByRoutineLogIdIn(Collection<Long> routineLogIds);

    Optional<CleaningDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);
}
