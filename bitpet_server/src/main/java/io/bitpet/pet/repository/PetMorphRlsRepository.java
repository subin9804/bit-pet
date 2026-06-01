package io.bitpet.pet.repository;

import io.bitpet.pet.domain.PetMorphRls;
import io.bitpet.pet.domain.PetMorphRlsId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PetMorphRlsRepository extends JpaRepository<PetMorphRls, PetMorphRlsId> {

    List<PetMorphRls> findAllByIdPetId(Long petId);

    void deleteAllByIdPetId(Long petId);
}
