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

    /**
     * 어떤 개체도 쓰지 않는 사용자 정의 모프를 지운다 (2026-10-30 사용자 결정).
     * 사용자가 직접 만든 것과 R__02 가 공식 목록에서 빼며 사용자 정의로 돌린 것을 똑같이 다룬다.
     *
     * <p>⚠️ 하루 지난 것만 — 앱은 모프를 먼저 만들고(POST) 개체 저장 때 붙이므로,
     * 방금 만든 모프를 지우면 그 사이에 저장한 개체가 MORPH_NOT_FOUND 로 실패한다.
     * 지운 개체(soft delete)의 연결은 아직 남아 있어 그 모프는 퍼지 뒤에 지워진다.
     */
    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @Query(value = """
            DELETE FROM morph_cd m
             WHERE m.is_user_defined = true
               AND m.updated_at < now() - interval '1 day'
               AND NOT EXISTS (SELECT 1 FROM pet_morph_rls r WHERE r.morph_id = m.id)
            """, nativeQuery = true)
    int deleteUnusedUserDefined();
}
