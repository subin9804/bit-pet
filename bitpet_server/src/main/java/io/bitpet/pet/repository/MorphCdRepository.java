package io.bitpet.pet.repository;

import io.bitpet.pet.domain.MorphCd;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MorphCdRepository extends JpaRepository<MorphCd, Long> {

    List<MorphCd> findAllBySpeciesIdAndIsActiveTrueOrderByDisplayOrderAsc(Long speciesId);

    /**
     * 종별 모프 목록 — 공식 카탈로그 + 요청자 본인의 커스텀 모프만.
     * 남이 만든 커스텀 모프(V7)는 제외한다.
     */
    @Query("""
            SELECT m FROM MorphCd m
            WHERE m.speciesId = :speciesId
              AND m.isActive = true
              AND (m.isUserDefined = false OR m.createdBy = :userId)
            ORDER BY m.displayOrder ASC
            """)
    List<MorphCd> findVisibleBySpecies(@Param("speciesId") Long speciesId,
                                       @Param("userId") Long userId);

    @Query("""
            SELECT m FROM MorphCd m
            WHERE m.speciesId = :speciesId
              AND m.isActive = true
              AND (m.isUserDefined = false OR m.createdBy = :userId)
              AND (
                    LOWER(m.nameKo) LIKE LOWER(CONCAT('%', :q, '%'))
                 OR LOWER(m.nameEn) LIKE LOWER(CONCAT('%', :q, '%'))
                 OR LOWER(m.aliasList) LIKE LOWER(CONCAT('%', :q, '%'))
              )
            ORDER BY m.displayOrder ASC
            """)
    List<MorphCd> searchAutocomplete(@Param("speciesId") Long speciesId,
                                     @Param("q") String q,
                                     @Param("userId") Long userId);

    /** 커스텀 모프 생성 시 같은 이름이 이미 있으면 재사용하기 위한 조회. uq_morph_cd_species_name_ko 대응. */
    Optional<MorphCd> findBySpeciesIdAndNameKo(Long speciesId, String nameKo);
}
