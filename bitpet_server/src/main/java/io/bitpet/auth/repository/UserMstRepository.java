package io.bitpet.auth.repository;

import io.bitpet.auth.domain.UserMst;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
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

    /** 보호자의 자녀 계정 목록 (V12). 만든 순서대로 — 보호자 화면에서 순서가 흔들리면 안 된다. */
    List<UserMst> findByGuardianUserIdOrderByIdAsc(Long guardianUserId);

    /**
     * 자녀가 남아 있는지 (V12). 탈퇴를 막는 근거다 —
     * DB 의 {@code ON DELETE RESTRICT} 는 마지막 방어선이고, 사용자에게는 여기서 이유를 설명해야 한다.
     */
    boolean existsByGuardianUserId(Long guardianUserId);

    Optional<UserMst> findByShareCode(String shareCode);

    boolean existsByShareCode(String shareCode);
}
