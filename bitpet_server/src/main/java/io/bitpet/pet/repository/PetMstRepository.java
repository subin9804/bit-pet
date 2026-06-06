package io.bitpet.pet.repository;

import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PetMstRepository extends JpaRepository<PetMst, Long> {

    boolean existsBySerialNo(String serialNo);

    Optional<PetMst> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);

    Optional<PetMst> findBySerialNo(String serialNo);

    List<PetMst> findAllByUserId(Long userId);

    List<PetMst> findAllByUserIdAndSpeciesId(Long userId, Long speciesId);

    List<PetMst> findAllByUserIdAndGender(Long userId, PetGender gender);

    // 그룹 할당/해제 (bulk)
    @Modifying
    @Query("UPDATE PetMst p SET p.groupId = :groupId WHERE p.userId = :userId")
    void assignGroupToUserPets(@Param("userId") Long userId, @Param("groupId") Long groupId);

    @Modifying
    @Query("UPDATE PetMst p SET p.groupId = NULL WHERE p.userId = :userId AND p.groupId = :groupId")
    void removeGroupFromUserPets(@Param("userId") Long userId, @Param("groupId") Long groupId);

    @Modifying
    @Query("UPDATE PetMst p SET p.groupId = NULL WHERE p.groupId = :groupId")
    void removeGroupFromAllPets(@Param("groupId") Long groupId);

    @Query("SELECT p FROM PetMst p WHERE p.userId = :userId " +
           "AND (:speciesId IS NULL OR p.species.id = :speciesId) " +
           "AND (:gender IS NULL OR p.gender = :gender) " +
           "AND (:name IS NULL OR LOWER(p.name) LIKE LOWER(CONCAT('%', :name, '%')))")
    List<PetMst> search(@Param("userId") Long userId,
                        @Param("speciesId") Long speciesId,
                        @Param("gender") PetGender gender,
                        @Param("name") String name);
}
