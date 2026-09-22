package io.bitpet.record.laying.repository;

import io.bitpet.record.laying.domain.LayingDtl;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * 산란 목록의 선택 필터.
 *
 * <p>⛔ JPQL 의 {@code (:from IS NULL OR l.laidAt >= :from)} 로 되돌리지 말 것.
 * 값이 null 이면 Hibernate 가 타입 힌트 없이 바인딩하고, PostgreSQL 은 {@code $4 IS NULL}
 * 만으로는 파라미터 타입을 정하지 못해 {@code could not determine data type of parameter $4}
 * 로 500 이 난다(Instant/timestamptz 에서 특히 잘 터진다). 게다가 그 형태는 인덱스도 못 탄다.
 * 여기서는 값이 있는 조건만 SQL 에 들어간다.
 */
public final class LayingDtlSpecs {

    private LayingDtlSpecs() {}

    /** {@code from} 이상, {@code toExclusive} 미만 */
    public static Specification<LayingDtl> filter(Long petId, Long matingId,
                                                  Instant from, Instant toExclusive) {
        return (root, query, cb) -> {
            List<Predicate> ps = new ArrayList<>();
            ps.add(cb.equal(root.get("petId"), petId));
            if (matingId != null)    ps.add(cb.equal(root.get("matingId"), matingId));
            if (from != null)        ps.add(cb.greaterThanOrEqualTo(root.get("laidAt"), from));
            if (toExclusive != null) ps.add(cb.lessThan(root.get("laidAt"), toExclusive));
            return cb.and(ps.toArray(Predicate[]::new));
        };
    }
}
