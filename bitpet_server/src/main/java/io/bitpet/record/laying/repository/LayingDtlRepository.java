package io.bitpet.record.laying.repository;

import io.bitpet.record.laying.domain.LayingDtl;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;

public interface LayingDtlRepository extends JpaRepository<LayingDtl, Long> {

    @Query("""
            SELECT l FROM LayingDtl l
            WHERE l.petId IN :petIds
              AND l.laidAt >= :from AND l.laidAt < :to
              AND l.deletedAt IS NULL
            ORDER BY l.laidAt DESC
            """)
    List<LayingDtl> findByPetIdsAndDateRange(@Param("petIds") Collection<Long> petIds,
                                              @Param("from") Instant from,
                                              @Param("to") Instant to);

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
