package io.bitpet.record.mating.repository;

import io.bitpet.record.mating.domain.MatingDtl;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;

public interface MatingDtlRepository extends JpaRepository<MatingDtl, Long>,
        JpaSpecificationExecutor<MatingDtl> {

    @Query("""
            SELECT m FROM MatingDtl m
            WHERE (m.malePetId IN :petIds OR m.femalePetId IN :petIds)
              AND m.triedAt >= :from AND m.triedAt < :to
              AND m.deletedAt IS NULL
            ORDER BY m.triedAt DESC
            """)
    List<MatingDtl> findByPetIdsAndDateRange(@Param("petIds") Collection<Long> petIds,
                                              @Param("from") Instant from,
                                              @Param("to") Instant to);

    // 선택 필터 목록은 MatingDtlSpecs 로 조립한다 — "(:x IS NULL OR ...)" JPQL 을 쓰지 말 것 (LayingDtlSpecs 주석 참고)

    /** 이 개체를 상대로 걸어둔 메이팅이 있는지 — 탈퇴·고아 정리에서 "남이 거는 참조" 판정 */
    @Query("""
            SELECT COUNT(m) > 0 FROM MatingDtl m
            WHERE (m.malePetId = :petId OR m.femalePetId = :petId) AND m.deletedAt IS NULL
            """)
    boolean existsReferenceTo(@Param("petId") Long petId);

    /**
     * 탈퇴 회원의 메이팅 기록 삭제 — 본인이 작성했거나, 암수 <b>둘 다</b> 본인 개체인 행.
     * 남이 작성하면서 내 개체를 상대로 걸어둔 행은 남긴다(그쪽 기록이고, 곧 참조 판정 대상이다).
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            DELETE FROM MatingDtl m
            WHERE m.createdByUserId = :userId
               OR (m.malePetId IN :petIds AND m.femalePetId IN :petIds)
            """)
    int deleteOwnedByUser(@Param("userId") Long userId,
                          @Param("petIds") Collection<Long> petIds);
}
