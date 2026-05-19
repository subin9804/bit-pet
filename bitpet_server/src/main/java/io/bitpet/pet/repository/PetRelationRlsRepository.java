package io.bitpet.pet.repository;

import io.bitpet.pet.domain.PetRelationRls;
import io.bitpet.pet.domain.RelationType;
import org.springframework.data.jpa.repository.JpaRepository;
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

    @Query("SELECT r.childPet FROM PetRelationRls r WHERE r.parentPet.id = :petId")
    List<io.bitpet.pet.domain.PetMst> findChildrenOf(@Param("petId") Long petId);

    @Query("SELECT r.parentPet FROM PetRelationRls r WHERE r.childPet.id = :petId")
    List<io.bitpet.pet.domain.PetMst> findParentsOf(@Param("petId") Long petId);
}
