package io.bitpet.community.controller;

import io.bitpet.auth.domain.AdminRole;
import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.auth.service.AdminGuard;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.community.domain.ReportStatus;
import io.bitpet.community.dto.ReportHandleRequest;
import io.bitpet.community.dto.ReportResponse;
import io.bitpet.community.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 신고 처리 큐.
 *
 * <p>🚨 {@code /api/v1/admin/**} 은 URL 로 보호되지 않는다 — SecurityConfig 는
 * {@code anyRequest().authenticated()} 뿐이라 <b>로그인만 하면 아무나 도달한다</b>.
 * 모든 메서드가 {@link AdminGuard} 를 직접 통과시킨다. 새 엔드포인트를 추가하면서 빠뜨리지 말 것.
 *
 * <p>등급을 <b>나열</b>하는 이유는 공지 권한과 같다 — 나중에 등급이 추가될 때 그 등급이
 * 신고 처리 권한을 조용히 물려받지 않게, 만드는 시점에 다시 판단하게 만든다.
 */
@Tag(name = "Admin - Report", description = "신고 처리 큐")
@RestController
@RequestMapping("/api/v1/admin/reports")
@RequiredArgsConstructor
public class ReportAdminController {

    private final ReportService reportService;
    private final AdminGuard adminGuard;

    @Operation(summary = "신고 목록", description = "status 를 주면 그 상태만 오래된 순, 없으면 전체 최신순")
    @GetMapping
    public ApiResponse<Page<ReportResponse>> list(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam(required = false) ReportStatus status,
            @PageableDefault(size = 20) Pageable pageable) {
        adminGuard.assertAnyRole(principal.userId(), AdminRole.SUPER_ADMIN, AdminRole.MODERATOR);
        return ApiResponse.ok(reportService.list(status, pageable));
    }

    @Operation(summary = "신고 처리",
            description = "RESOLVED(위반 인정) 또는 REJECTED(위반 아님) + 조치(NONE/BLIND/DELETE). "
                    + "BLIND 는 내용을 지우지 않고 가리기만 하므로 오판이어도 되돌릴 수 있다.")
    @PostMapping("/{reportId}/handle")
    public ApiResponse<ReportResponse> handle(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long reportId,
            @Valid @RequestBody ReportHandleRequest request) {
        adminGuard.assertAnyRole(principal.userId(), AdminRole.SUPER_ADMIN, AdminRole.MODERATOR);
        return ApiResponse.ok(reportService.handle(principal.userId(), reportId, request));
    }
}
