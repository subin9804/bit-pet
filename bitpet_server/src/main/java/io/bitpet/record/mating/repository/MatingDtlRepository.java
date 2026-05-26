package io.bitpet.record.mating.repository;

import io.bitpet.record.mating.domain.MatingDtl;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MatingDtlRepository extends JpaRepository<MatingDtl, Long> {

    @Query("""
            SELECT m FROM MatingDtl m
            WHERE (m.malePetId = :petId OR m.femalePetId = :petId)
              AND (:seasonLabel IS NULL OR m.seasonLabel = :seasonLabel)
              AND (:isSuccessful IS NULL OR m.isSuccessful = :isSuccessful)
            ORDER BY m.triedAt DESC
            """)
    Page<MatingDtl> findByPetIdWithFilters(
            @Param("petId") Long petId,
            @Param("seasonLabel") String seasonLabel,
            @Param("isSuccessful") Boolean isSuccessful,
            Pageable pageable);
}
