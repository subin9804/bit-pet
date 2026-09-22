package io.bitpet.record.mating.repository;

import io.bitpet.record.mating.domain.MatingDtl;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

/**
 * 메이팅 목록의 선택 필터. null 파라미터를 JPQL 에 넘기지 않는 이유는
 * {@link io.bitpet.record.laying.repository.LayingDtlSpecs} 주석 참고.
 */
public final class MatingDtlSpecs {

    private MatingDtlSpecs() {}

    /** 암수 어느 쪽이든 {@code petId} 가 걸린 메이팅 */
    public static Specification<MatingDtl> filter(Long petId, String seasonLabel, Boolean isSuccessful) {
        return (root, query, cb) -> {
            List<Predicate> ps = new ArrayList<>();
            ps.add(cb.or(cb.equal(root.get("malePetId"), petId),
                         cb.equal(root.get("femalePetId"), petId)));
            if (seasonLabel != null)  ps.add(cb.equal(root.get("seasonLabel"), seasonLabel));
            if (isSuccessful != null) ps.add(cb.equal(root.get("isSuccessful"), isSuccessful));
            return cb.and(ps.toArray(Predicate[]::new));
        };
    }
}
