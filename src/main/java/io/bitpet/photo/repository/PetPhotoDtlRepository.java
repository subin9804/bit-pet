package io.bitpet.photo.repository;

import io.bitpet.photo.domain.PetPhotoDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PetPhotoDtlRepository extends JpaRepository<PetPhotoDtl, Long> {

    List<PetPhotoDtl> findAllByPetIdOrderByTakenAtDesc(Long petId);
}
