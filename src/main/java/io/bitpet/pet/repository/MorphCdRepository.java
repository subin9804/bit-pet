package io.bitpet.pet.repository;

import io.bitpet.pet.domain.MorphCd;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MorphCdRepository extends JpaRepository<MorphCd, Long> {

    List<MorphCd> findAllBySpeciesIdAndIsActiveTrueOrderByDisplayOrderAsc(Long speciesId);
}
