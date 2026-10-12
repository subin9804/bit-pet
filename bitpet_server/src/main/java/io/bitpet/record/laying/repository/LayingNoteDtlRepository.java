package io.bitpet.record.laying.repository;

import io.bitpet.record.laying.domain.LayingNoteDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LayingNoteDtlRepository extends JpaRepository<LayingNoteDtl, Long> {

    /** 클러치 상세는 항상 최신 날짜부터 읽는다. 같은 날이 여러 줄이면 나중에 쓴 것이 위로 */
    List<LayingNoteDtl> findAllByLayingIdOrderByNotedAtDescIdDesc(Long layingId);

    Optional<LayingNoteDtl> findByIdAndLayingId(Long id, Long layingId);

    List<LayingNoteDtl> findAllByLayingIdIn(List<Long> layingIds);
}
