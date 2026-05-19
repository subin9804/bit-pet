package io.bitpet.notification.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.notification.dto.NotificationLogResponse;
import io.bitpet.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final NotificationService notificationService;

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
}
