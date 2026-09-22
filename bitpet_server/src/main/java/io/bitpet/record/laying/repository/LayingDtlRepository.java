package io.bitpet.record.laying.repository;

import io.bitpet.record.laying.domain.LayingDtl;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;

public interface LayingDtlRepository extends JpaRepository<LayingDtl, Long>,
        JpaSpecificationExecutor<LayingDtl> {

    @Query("""
            SELECT l FROM LayingDtl l
            WHERE l.petId IN :petIds
              AND l.laidAt >= :from AND l.laidAt < :to
              AND l.deletedAt IS NULL
            ORDER BY l.laidAt DESC
            """)
    List<LayingDtl> findByPetIdsAndDateRange(@Param("petIds") Collection<Long> petIds,
                                              @Param("from") Instant from,
                                              @Param("to") Instant to);

    // 선택 필터 목록은 LayingDtlSpecs 로 조립한다 — "(:x IS NULL OR ...)" JPQL 을 쓰지 말 것 (Specs 주석 참고)
}
