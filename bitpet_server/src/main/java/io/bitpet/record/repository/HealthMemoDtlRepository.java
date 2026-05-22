package io.bitpet.record.repository;

import io.bitpet.record.domain.HealthMemoDtl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface HealthMemoDtlRepository extends JpaRepository<HealthMemoDtl, Long> {

    List<HealthMemoDtl> findAllByPetIdOrderByRecordedAtDesc(Long petId);

    List<HealthMemoDtl> findAllByPetIdInOrderByRecordedAtDesc(Collection<Long> petIds, Pageable pageable);

    Optional<HealthMemoDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);
}
