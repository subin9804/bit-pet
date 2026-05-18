package io.bitpet.record.repository;

import io.bitpet.record.domain.WeightDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface WeightDtlRepository extends JpaRepository<WeightDtl, Long> {

    List<WeightDtl> findAllByPetIdOrderByMeasuredAtDesc(Long petId);
}
