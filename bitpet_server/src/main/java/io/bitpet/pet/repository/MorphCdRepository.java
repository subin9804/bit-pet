package io.bitpet.pet.repository;

import io.bitpet.pet.domain.MorphCd;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface MorphCdRepository extends JpaRepository<MorphCd, Long> {

    List<MorphCd> findAllBySpeciesIdAndIsActiveTrueOrderByDisplayOrderAsc(Long speciesId);

    @Query("""
            SELECT m FROM MorphCd m
            WHERE m.speciesId = :speciesId
              AND m.isActive = true
              AND (
                    LOWER(m.nameKo) LIKE LOWER(CONCAT('%', :q, '%'))
                 OR LOWER(m.nameEn) LIKE LOWER(CONCAT('%', :q, '%'))
                 OR LOWER(m.aliasList) LIKE LOWER(CONCAT('%', :q, '%'))
              )
            ORDER BY m.displayOrder ASC
            """)
    List<MorphCd> searchAutocomplete(@Param("speciesId") Long speciesId, @Param("q") String q);
}
