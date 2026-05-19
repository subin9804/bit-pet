package io.bitpet.pet.repository;

import io.bitpet.pet.domain.MatingRls;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface MatingRlsRepository extends JpaRepository<MatingRls, Long> {

    @Query("SELECT m FROM MatingRls m WHERE m.malePet.id = :petId OR m.femalePet.id = :petId ORDER BY m.matingDate DESC")
    List<MatingRls> findAllByPetId(@Param("petId") Long petId);
}
