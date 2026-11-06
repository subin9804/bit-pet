package io.bitpet.auth.repository;

import io.bitpet.auth.domain.UserMst;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface UserMstRepository extends JpaRepository<UserMst, Long> {

    Optional<UserMst> findByEmail(String email);

    Optional<UserMst> findFirstByEmailIgnoreCaseOrderByIdAsc(String email);

    /**
     * 이메일로 계정 찾기 — 대소문자 무시. 정확히 같은 주소가 있으면 그게 먼저다:
     * 정규화 전에 대소문자만 다른 두 계정이 생겼을 수 있어서, 원래 붙던 계정을 바꾸지 않는다.
     */
    default Optional<UserMst> findByEmailLoose(String email) {
        if (email == null) return Optional.empty();
        return findByEmail(email.trim())
                .or(() -> findFirstByEmailIgnoreCaseOrderByIdAsc(email.trim()));
    }

    /** 가입 중복 확인 — 대소문자 무시 ({@code EmailPolicy}). */
    boolean existsByEmailIgnoreCase(String email);

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

    /** 해제 전 자녀 계정 후보 (V23). 나이 판정 전이라 바로 쓰지 말고 {@link #findChildrenUnderGuardian} 을 쓴다 */
    List<UserMst> findByGuardianUserIdAndGuardianReleasedAtIsNullOrderByIdAsc(Long guardianUserId);

    /**
     * 보호자 아래에 있는 자녀 계정 (V12·V23). 만든 순서대로 — 보호자 화면에서 순서가 흔들리면 안 된다.
     *
     * <p>만 14세가 지난 계정은 해제 배치가 아직 안 돌았어도 뺀다 ({@link UserMst#isUnderGuardian()}).
     * 자녀 목록·자녀 수 제한·보호자 탈퇴 차단이 모두 이걸 쓴다 — 셋이 다른 기준을 쓰면
     * "목록엔 없는데 탈퇴는 막힌다" 가 된다.
     */
    default List<UserMst> findChildrenUnderGuardian(Long guardianUserId) {
        return findByGuardianUserIdAndGuardianReleasedAtIsNullOrderByIdAsc(guardianUserId).stream()
                .filter(UserMst::isUnderGuardian)
                .toList();
    }

    /** 해제 배치 대상 — 보호자가 있고, 아직 해제 전이며, 생일 기준 만 14세가 지난 계정 */
    @Query("""
            select u from UserMst u
            where u.guardianUserId is not null
              and u.guardianReleasedAt is null
              and u.birthDate <= :cutoff
            """)
    List<UserMst> findGuardianReleaseDue(
            @Param("cutoff") LocalDate cutoff);

    Optional<UserMst> findByShareCode(String shareCode);

    boolean existsByShareCode(String shareCode);
}
