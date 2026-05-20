package io.bitpet.record.repository;

import io.bitpet.record.domain.CleaningDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CleaningDtlRepository extends JpaRepository<CleaningDtl, Long> {

    List<CleaningDtl> findAllByPetIdOrderByCleanedAtDesc(Long petId);

    Optional<CleaningDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);
}
