package io.bitpet.record.repository;

import io.bitpet.record.domain.WeightDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface WeightDtlRepository extends JpaRepository<WeightDtl, Long> {

    List<WeightDtl> findAllByPetIdOrderByMeasuredAtDesc(Long petId);

    Optional<WeightDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);
}
