package io.bitpet.pet.repository;

import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.List;

/**
 * 내 개체 검색의 선택 필터. null 파라미터를 JPQL 에 넘기지 않는 이유는
 * {@link io.bitpet.record.laying.repository.LayingDtlSpecs} 주석 참고.
 */
public final class PetMstSpecs {

    private PetMstSpecs() {}

    public static Specification<PetMst> search(Long userId, Long speciesId, PetGender gender, String name) {
        return (root, query, cb) -> {
            List<Predicate> ps = new ArrayList<>();
            ps.add(cb.equal(root.get("userId"), userId));
            if (speciesId != null) ps.add(cb.equal(root.get("species").get("id"), speciesId));
            if (gender != null)    ps.add(cb.equal(root.get("gender"), gender));
            if (StringUtils.hasText(name)) {
                ps.add(cb.like(cb.lower(root.get("name")), "%" + name.toLowerCase() + "%"));
            }
            return cb.and(ps.toArray(Predicate[]::new));
        };
    }
}
