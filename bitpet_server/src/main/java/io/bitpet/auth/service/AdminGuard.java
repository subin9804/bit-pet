package io.bitpet.auth.service;

import io.bitpet.auth.repository.AdminRoleRlsRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
}
