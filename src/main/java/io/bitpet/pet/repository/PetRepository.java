package io.bitpet.pet.repository;

import io.bitpet.pet.domain.Pet;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PetRepository extends JpaRepository<Pet, Long> {

    boolean existsBySerialNumber(String serialNumber);

    Optional<Pet> findBySerialNumber(String serialNumber);

    List<Pet> findAllByOwnerId(Long ownerId);

    long count();
}
