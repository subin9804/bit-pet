package io.bitpet.record.repository;

import io.bitpet.record.domain.FeedingDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FeedingDtlRepository extends JpaRepository<FeedingDtl, Long> {

    List<FeedingDtl> findAllByPetIdOrderByFedAtDesc(Long petId);

    Optional<FeedingDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);
}
