package io.bitpet.pet.repository;

import io.bitpet.pet.domain.SpeciesCd;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpeciesCdRepository extends JpaRepository<SpeciesCd, Long> {

    List<SpeciesCd> findAllByIsActiveTrueOrderByDisplayOrderAsc();

    List<SpeciesCd> findAllByCategoryAndIsActiveTrueOrderByDisplayOrderAsc(String category);

    Optional<SpeciesCd> findByCode(String code);
}
