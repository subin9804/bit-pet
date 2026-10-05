package io.bitpet.pet.repository;

import io.bitpet.pet.domain.PetKeeperRls;
import io.bitpet.pet.domain.PetKeeperRlsId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface PetKeeperRlsRepository
        extends JpaRepository<PetKeeperRls, PetKeeperRlsId> {

    /** 특정 유저가 특정 개체의 사육자(OWNER 또는 KEEPER)인지 */
    boolean existsByIdPetIdAndIdUserId(Long petId, Long userId);

    Optional<PetKeeperRls> findByIdPetIdAndIdUserId(Long petId, Long userId);

    /** 개체의 모든 사육자 */
    List<PetKeeperRls> findAllByIdPetId(Long petId);

    /** 유저가 사육하는 모든 개체 (OWNER + KEEPER) */
    List<PetKeeperRls> findAllByIdUserId(Long userId);

    /** 개체의 소유자 행 */
    @Query("SELECT k FROM PetKeeperRls k WHERE k.id.petId = :petId AND k.role = 'OWNER'")
    Optional<PetKeeperRls> findOwner(@Param("petId") Long petId);

    /** 개체의 소유자 외 KEEPER 목록 (승격 후보) — 합류 순 */
    @Query("SELECT k FROM PetKeeperRls k WHERE k.id.petId = :petId AND k.role = 'KEEPER' ORDER BY k.joinedAt ASC")
    List<PetKeeperRls> findKeepers(@Param("petId") Long petId);

    /** 유저가 사육하는 개체 id 목록 */
    @Query("SELECT k.id.petId FROM PetKeeperRls k WHERE k.id.userId = :userId")
    List<Long> findPetIdsByUserId(@Param("userId") Long userId);

    /**
     * 유저가 소유(OWNER)한 개체 수 — 상한 검사용.
     *
     * <p>행을 세는 게 아니라 <b>살아 있는 개체를 센다</b>: {@code PetMst} 서브쿼리를 거치는 건
     * {@code @SQLRestriction("deleted_at IS NULL")} 을 타려는 것이다. 키퍼 행은 개체를 지워도
     * 남을 수 있어서, 직접 세면 지운 개체가 평생 자리를 차지한다.
     *
     * <p>이별(폐사)한 개체는 <b>센다</b> — 목록에 계속 보이고 기록도 그대로 남아 있으므로
     * 자리를 쓰는 것은 사실이다. 공유받은(KEEPER) 개체는 세지 않는다: 남의 개체가 내 한도를
     * 깎으면 같이 키우자는 초대를 거절할 이유가 생긴다.
     */
    @Query("""
            SELECT COUNT(k) FROM PetKeeperRls k
            WHERE k.id.userId = :userId
              AND k.role = 'OWNER'
              AND k.id.petId IN (SELECT p.id FROM PetMst p)
            """)
    long countOwnedByUser(@Param("userId") Long userId);

    /** 유저가 소유(OWNER)한 개체 행 목록 — 탈퇴 시 승격/삭제 판단용 */
    @Query("SELECT k FROM PetKeeperRls k WHERE k.id.userId = :userId AND k.role = 'OWNER'")
    List<PetKeeperRls> findOwnedByUser(@Param("userId") Long userId);

    void deleteByIdPetIdAndIdUserId(Long petId, Long userId);
}
