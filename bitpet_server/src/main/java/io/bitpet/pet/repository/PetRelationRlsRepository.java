package io.bitpet.pet.repository;

import io.bitpet.pet.domain.PetRelationRls;
import io.bitpet.pet.domain.RelationType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface PetRelationRlsRepository extends JpaRepository<PetRelationRls, Long> {

    List<PetRelationRls> findAllByChildPetId(Long childPetId);

    List<PetRelationRls> findAllByParentPetId(Long parentPetId);

    Optional<PetRelationRls> findByParentPetIdAndChildPetIdAndRelationType(
            Long parentPetId, Long childPetId, RelationType relationType);

    boolean existsByParentPetIdAndChildPetIdAndRelationType(
            Long parentPetId, Long childPetId, RelationType relationType);

    /** 역방향 존재 여부 — 바로 되짚는 순환(A→B 인데 B→A) 차단용 */
    boolean existsByParentPetIdAndChildPetId(Long parentPetId, Long childPetId);

    /**
     * 이 개체를 <b>부모로</b> 걸어둔 가계도가 있는지 — 탈퇴 시 "남이 거는 참조" 판정.
     * 자식으로 걸린 행은 세지 않는다. 그건 이 개체 자신의 가계도라 함께 사라져도 된다.
     */
    boolean existsByParentPetId(Long parentPetId);

    /**
     * 탈퇴 회원 개체끼리의 상호 참조 제거 — 부모·자식이 <b>둘 다</b> 이 회원 개체인 행만 지운다.
     *
     * <p>이걸 먼저 하지 않으면 "가입하고 자기 개체 몇 마리를 서로 연결한 뒤 바로 탈퇴한" 계정의
     * 개체가 서로를 참조한다는 이유로 전부 보존돼 쓰레기 데이터가 된다.
     * 반대로 한쪽만 걸린 행은 남긴다 — 남의 개체를 부모로 적어둔 행은 익명화 개체의 혈통이고,
     * 남의 자식이 내 개체를 부모로 건 행은 개체를 지우지 못하게 붙잡는 참조 그 자체다.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM PetRelationRls r WHERE r.parentPet.id IN :petIds AND r.childPet.id IN :petIds")
    int deleteIntraAccountRelations(@Param("petIds") java.util.Collection<Long> petIds);

    @Query("SELECT r.childPet FROM PetRelationRls r WHERE r.parentPet.id = :petId")
    List<io.bitpet.pet.domain.PetMst> findChildrenOf(@Param("petId") Long petId);

    @Query("SELECT r.parentPet FROM PetRelationRls r WHERE r.childPet.id = :petId")
    List<io.bitpet.pet.domain.PetMst> findParentsOf(@Param("petId") Long petId);
}
