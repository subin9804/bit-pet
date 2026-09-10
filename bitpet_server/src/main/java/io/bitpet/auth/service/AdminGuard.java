package io.bitpet.auth.service;

import io.bitpet.auth.domain.AdminRole;
import io.bitpet.auth.repository.AdminRoleRlsRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;

/**
 * 어드민 권한 판정 (admin_role_rls).
 *
 * <p>SecurityConfig 는 {@code publicPaths} 외 전부를 {@code authenticated()} 로만 막는다.
 * 즉 <b>URL 만으로는 {@code /api/v1/admin/**} 이 보호되지 않는다</b> — 로그인한 아무 계정이나
 * 도달한다. 어드민 컨트롤러는 반드시 이 가드를 직접 통과시켜야 한다.
 *
 * <p>JWT 의 role 클레임을 믿지 않는 이유: 토큰은 발급 시점의 스냅샷이라 권한을 회수해도
 * 만료 전까지 살아 있다. 되돌릴 수 없는 동작(태그 영구 차단)을 여는 문이므로 매번 DB를 본다.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminGuard {

    private final AdminRoleRlsRepository adminRepository;

    /** 어드민이 아니면 403. 역할 종류(SUPER_ADMIN/MODERATOR)는 구분하지 않는다 */
    public void assertAdmin(Long userId) {
        if (!isAdmin(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
    }

    public boolean isAdmin(Long userId) {
        return userId != null && adminRepository.existsByUserId(userId);
    }

    /**
     * 특정 등급이 아니면 403.
     *
     * <p>등급을 <b>포함 관계로 보지 않는다</b> — SUPER_ADMIN 이라고 해서 MODERATOR 를
     * 자동으로 갖는 게 아니라, 두 등급을 다 주고 싶으면 admin_role_rls 에 행을 2개 넣는다.
     * (테이블의 유니크 제약이 (user_id, role) 이라 애초에 그렇게 쓰라고 만들어진 구조다.)
     * 등급 사이에 상하 관계를 코드에 박아두면, 나중에 "이건 MODERATOR 만 되고 SUPER_ADMIN 은
     * 안 되는 동작"이 생겼을 때 되돌릴 수 없다.
     */
    public void assertRole(Long userId, AdminRole role) {
        if (!hasRole(userId, role)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
    }

    public boolean hasRole(Long userId, AdminRole role) {
        return userId != null && adminRepository.existsByUserIdAndRole(userId, role.name());
    }

    /**
     * 나열한 등급 중 하나도 없으면 403.
     *
     * <p>"등급 여러 개가 되는 동작"에 {@link #assertAdmin} 대신 이걸 쓴다. assertAdmin 은
     * 등급을 안 보므로, 나중에 등급이 늘어나면 그 등급이 권한을 <b>조용히 물려받는다</b>.
     * 여기에 나열해두면 새 등급을 만들 때 어디에 넣을지 다시 판단하게 된다.
     */
    public void assertAnyRole(Long userId, AdminRole... roles) {
        for (AdminRole role : roles) {
            if (hasRole(userId, role)) return;
        }
        throw new BusinessException(ErrorCode.FORBIDDEN);
    }

    /** 이 사용자가 가진 등급 전부. 앱이 UI(공지 작성 버튼 등)를 켤지 판단하는 데 쓴다 */
    public List<AdminRole> rolesOf(Long userId) {
        if (userId == null) return List.of();
        return adminRepository.findAllByUserId(userId).stream()
                .map(r -> {
                    // DB 에 코드가 모르는 등급이 들어 있어도 조회가 통째로 터지면 안 된다.
                    try { return AdminRole.valueOf(r.getRole()); }
                    catch (IllegalArgumentException e) { return null; }
                })
                .filter(Objects::nonNull)
                .toList();
    }
}
