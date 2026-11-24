package io.bitpet.notification.controller;

import io.bitpet.auth.domain.AdminRole;
import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.auth.service.AdminGuard;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.notification.dto.BroadcastPreviewResponse;
import io.bitpet.notification.dto.BroadcastRequest;
import io.bitpet.notification.dto.BroadcastResponse;
import io.bitpet.notification.service.BroadcastService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 전체 푸시. 🚨 URL 로 보호되지 않는다 — 메서드마다 가드.
 * 전원에게 가는 되돌릴 수 없는 동작이라 SUPER_ADMIN 만 (MODERATOR 는 신고 처리 등급).
 */
@Tag(name = "Admin - Push", description = "전체 푸시 발송")
@RestController
@RequestMapping("/api/v1/admin/push")
@RequiredArgsConstructor
public class BroadcastAdminController {

    private final BroadcastService broadcastService;
    private final AdminGuard adminGuard;

    @Operation(summary = "발송 대상 수 미리보기", description = "전체 / 마케팅 동의자 수, 지금이 광고 금지 시간인지")
    @GetMapping("/preview")
    public ApiResponse<BroadcastPreviewResponse> preview(@AuthenticationPrincipal AuthPrincipal principal) {
        adminGuard.assertRole(principal.userId(), AdminRole.SUPER_ADMIN);
        return ApiResponse.ok(broadcastService.preview());
    }

    @Operation(summary = "전체 푸시 발송",
            description = "marketing=true 면 동의자에게만 (광고) 머리말·수신거부 안내를 붙여 보낸다. 21~08시는 거부. 발송은 비동기")
    @PostMapping("/broadcast")
    public ApiResponse<BroadcastResponse> send(@AuthenticationPrincipal AuthPrincipal principal,
                                               @Valid @RequestBody BroadcastRequest req) {
        adminGuard.assertRole(principal.userId(), AdminRole.SUPER_ADMIN);
        return ApiResponse.ok(broadcastService.send(principal.userId(), req));
    }

    @Operation(summary = "발송 이력", description = "최근 것부터")
    @GetMapping("/broadcasts")
    public ApiResponse<Page<BroadcastResponse>> history(@AuthenticationPrincipal AuthPrincipal principal,
                                                        @PageableDefault(size = 20) Pageable pageable) {
        adminGuard.assertRole(principal.userId(), AdminRole.SUPER_ADMIN);
        return ApiResponse.ok(broadcastService.history(pageable));
    }
}
