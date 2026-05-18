package io.bitpet.record.repository;

import io.bitpet.record.domain.HealthMemoDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HealthMemoDtlRepository extends JpaRepository<HealthMemoDtl, Long> {

    List<HealthMemoDtl> findAllByPetIdOrderByRecordedAtDesc(Long petId);
}
