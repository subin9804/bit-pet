package io.bitpet.record.laying.repository;

import io.bitpet.record.laying.domain.LayingHatchDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LayingHatchDtlRepository extends JpaRepository<LayingHatchDtl, Long> {

    List<LayingHatchDtl> findAllByLayingIdOrderByCreatedAtAsc(Long layingId);

    Optional<LayingHatchDtl> findByIdAndLayingId(Long id, Long layingId);
}
