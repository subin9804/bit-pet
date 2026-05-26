package io.bitpet.record.laying.repository;

import io.bitpet.record.laying.domain.LayingDtl;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;

public interface LayingDtlRepository extends JpaRepository<LayingDtl, Long> {

    @Query("""
            SELECT l FROM LayingDtl l
            WHERE l.petId = :petId
              AND (:matingId IS NULL OR l.matingId = :matingId)
              AND (:from IS NULL OR l.laidAt >= :from)
              AND (:to IS NULL OR l.laidAt <= :to)
            ORDER BY l.laidAt DESC
            """)
    Page<LayingDtl> findByPetIdWithFilters(
            @Param("petId") Long petId,
            @Param("matingId") Long matingId,
            @Param("from") Instant from,
            @Param("to") Instant to,
            Pageable pageable);
}
