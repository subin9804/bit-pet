package io.bitpet.record.repository;

import io.bitpet.record.domain.CleaningDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CleaningDtlRepository extends JpaRepository<CleaningDtl, Long> {

    List<CleaningDtl> findAllByPetIdOrderByCleanedAtDesc(Long petId);
}
