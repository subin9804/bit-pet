package io.bitpet.record.laying.repository;

import io.bitpet.record.laying.domain.LayingHatchDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LayingHatchDtlRepository extends JpaRepository<LayingHatchDtl, Long> {

    List<LayingHatchDtl> findAllByLayingIdOrderByCreatedAtAsc(Long layingId);

    Optional<LayingHatchDtl> findByIdAndLayingId(Long id, Long layingId);

    /** 개체 삭제 시 그 개체를 가리키는 알을 찾아 연결을 끊는다 */
    List<LayingHatchDtl> findAllByHatchedPetId(Long hatchedPetId);
}
