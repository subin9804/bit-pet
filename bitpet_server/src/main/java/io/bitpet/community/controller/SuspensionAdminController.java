package io.bitpet.community.controller;

import io.bitpet.auth.domain.AdminRole;
import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.auth.service.AdminGuard;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.community.dto.SuspensionResponse;
import io.bitpet.community.service.SuspensionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 커뮤니티 이용 정지 — 지금 정지 중인 목록과 기간 전 해제. 정지 자체는 신고 처리(SUSPEND)로만 생긴다.
 *
 * <p>🚨 URL 로 보호되지 않는다 — 메서드마다 {@link AdminGuard} 를 직접 부른다 (신고 큐와 같은 등급).
 */
@Tag(name = "Admin - Suspension", description = "커뮤니티 이용 정지")
@RestController
@RequestMapping("/api/v1/admin/suspensions")
@RequiredArgsConstructor
public class SuspensionAdminController {

    private final SuspensionService suspensionService;
    private final AdminGuard adminGuard;

    @Operation(summary = "정지 중인 계정", description = "기간이 남았거나 영구인 정지만. 최근 것부터")
    @GetMapping
    public ApiResponse<List<SuspensionResponse>> listActive(@AuthenticationPrincipal AuthPrincipal principal) {
        adminGuard.assertAnyRole(principal.userId(), AdminRole.SUPER_ADMIN, AdminRole.MODERATOR);
        return ApiResponse.ok(suspensionService.listActive());
    }

    @Operation(summary = "정지 해제", description = "기간 전에 푼다. 함께 가려진 글·댓글은 신고 목록의 '가림 해제'로 따로 되돌린다")
    @PostMapping("/{suspensionId}/release")
    public ApiResponse<Void> release(@AuthenticationPrincipal AuthPrincipal principal,
                                     @PathVariable Long suspensionId) {
        adminGuard.assertAnyRole(principal.userId(), AdminRole.SUPER_ADMIN, AdminRole.MODERATOR);
        suspensionService.release(suspensionId, principal.userId());
        return ApiResponse.ok(null);
    }
}
