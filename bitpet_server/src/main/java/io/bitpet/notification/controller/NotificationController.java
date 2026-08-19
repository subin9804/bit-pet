package io.bitpet.notification.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.notification.dto.NotificationLogResponse;
import io.bitpet.notification.dto.NotificationPrefResponse;
import io.bitpet.notification.dto.NotificationPrefUpdateRequest;
import io.bitpet.notification.service.NotificationPrefService;
import io.bitpet.notification.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final NotificationService notificationService;
    private final NotificationPrefService notificationPrefService;

    @GetMapping
    public ApiResponse<List<NotificationLogResponse>> listNotifications(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(notificationService.listNotifications(principal.userId()));
    }

    @PatchMapping("/{id}/read")
    public ApiResponse<NotificationLogResponse> markRead(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long id) {
        return ApiResponse.ok(notificationService.markRead(principal.userId(), id));
    }

    // -------------------------------------------------------------------------
    // 알림 설정
    // -------------------------------------------------------------------------

    @Operation(summary = "알림 수신 설정 조회")
    @GetMapping("/settings")
    public ApiResponse<NotificationPrefResponse> getSettings(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(notificationPrefService.getPref(principal.userId()));
    }

    @Operation(summary = "알림 수신 설정 변경 (보낸 항목만 반영)",
            description = """
                    누른 토글 하나만 보내면 된다. null 인 필드는 그대로 둔다.
                    marketing 을 보내면 알림 설정이 아니라 약관 동의 이력에 행이 하나 쌓인다 —
                    마케팅 수신은 취향이 아니라 법이 요구하는 동의 기록이다.
                    공지·점검(SYSTEM)은 끌 수 없어서 요청 필드가 아예 없다.""")
    @PatchMapping("/settings")
    public ApiResponse<NotificationPrefResponse> updateSettings(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody NotificationPrefUpdateRequest request) {
        return ApiResponse.ok(notificationPrefService.updatePref(principal.userId(), request));
    }
}
