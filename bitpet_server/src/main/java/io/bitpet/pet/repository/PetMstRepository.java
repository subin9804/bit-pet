package io.bitpet.pet.repository;

import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface PetMstRepository extends JpaRepository<PetMst, Long> {

    boolean existsBySerialNo(String serialNo);

    Optional<PetMst> findBySerialNo(String serialNo);

    List<PetMst> findAllByUserId(Long userId);

    List<PetMst> findAllByUserIdAndSpeciesId(Long userId, Long speciesId);

    List<PetMst> findAllByUserIdAndGender(Long userId, PetGender gender);

    @Query("SELECT p FROM PetMst p WHERE p.userId = :userId " +
           "AND (:speciesId IS NULL OR p.species.id = :speciesId) " +
           "AND (:gender IS NULL OR p.gender = :gender) " +
           "AND (:name IS NULL OR LOWER(p.name) LIKE LOWER(CONCAT('%', :name, '%')))")
    List<PetMst> search(@Param("userId") Long userId,
                        @Param("speciesId") Long speciesId,
                        @Param("gender") PetGender gender,
                        @Param("name") String name);
}
