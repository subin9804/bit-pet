package io.bitpet.pet.repository;

import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PetMstRepository extends JpaRepository<PetMst, Long>,
        JpaSpecificationExecutor<PetMst> {

    boolean existsBySerialNo(String serialNo);

    Optional<PetMst> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);

    Optional<PetMst> findBySerialNo(String serialNo);

    List<PetMst> findAllByUserId(Long userId);

    /** 공개 프로필용 — private_yn = 'N' 인 개체만 */
    List<PetMst> findAllByUserIdAndPrivateYn(Long userId, String privateYn);

    List<PetMst> findAllByUserIdAndSpeciesId(Long userId, Long speciesId);

    List<PetMst> findAllByUserIdAndGender(Long userId, PetGender gender);

    /**
     * 같은 사람이 키우는 개체 중 이름이 겹치는 게 있는지.
     *
     * <p>판정 범위는 <b>{@code pet_keeper_rls} 기준</b>이지 {@code pet_mst.user_id} 가 아니다 —
     * 공유받은 개체도 내 목록에 함께 뜨므로, 그 사이에서 이름이 겹치면 구분이 안 되는 건 똑같다.
     *
     * <p>{@code excludePetId} 는 수정 시 자기 자신을 제외하기 위한 것이다. 등록에는 제외할
     * 개체가 없으므로 호출부가 {@code 0L}(존재할 수 없는 id)을 넘긴다 — JPQL 에
     * {@code (:x IS NULL OR ...)} 를 섞지 않기 위한 선택이다.
     *
     * <p>⚠️ {@code name} 은 <b>호출부가 이미 trim + 소문자로 정규화해서</b> 넘긴다
     * ({@link io.bitpet.pet.service.PetService} 의 {@code assertNameAvailable}).
     * 양쪽을 다 {@code LOWER(TRIM(...))} 로 감싸면 파라미터 쪽 TRIM 이 적용되지 않아
     * " 레오 " 가 "레오" 와 다른 이름으로 통과한다 — 정규화는 자바에서 한다.
     *
     * <p>이별(폐사)한 개체도 센다. 목록에 계속 보이는 개체라 이름이 겹치면 헷갈리는 건 같다.
     */
    @Query("""
            SELECT COUNT(p) > 0 FROM PetMst p
            WHERE p.id IN (SELECT k.id.petId FROM PetKeeperRls k WHERE k.id.userId = :userId)
              AND LOWER(TRIM(p.name)) = :name
              AND p.id <> :excludePetId
            """)
    boolean existsDuplicateName(@Param("userId") Long userId,
                                @Param("name") String name,
                                @Param("excludePetId") Long excludePetId);

    // 선택 필터 검색은 PetMstSpecs 로 조립한다 — "(:x IS NULL OR ...)" JPQL 을 쓰지 말 것 (LayingDtlSpecs 주석 참고)
}
