package io.bitpet.auth.repository;

import io.bitpet.auth.domain.UserMst;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserMstRepository extends JpaRepository<UserMst, Long> {

    Optional<UserMst> findByEmail(String email);

    boolean existsByEmail(String email);

    /**
     * 닉네임 중복 확인. 대소문자를 구분하지 않는다 — DB 의
     * {@code idx_user_mst_name_unique} 가 {@code lower(name)} 기준이므로 범위를 맞춘다.
     */
    boolean existsByNameIgnoreCase(String name);

    /**
     * 본인을 제외한 닉네임 중복 확인. 프로필 수정에서 쓴다 —
     * 이게 없으면 자기 닉네임을 그대로 두고 저장하는 것조차 "중복"으로 막힌다.
     */
    boolean existsByNameIgnoreCaseAndIdNot(String name, Long id);

    Optional<UserMst> findByShareCode(String shareCode);

    boolean existsByShareCode(String shareCode);
}
