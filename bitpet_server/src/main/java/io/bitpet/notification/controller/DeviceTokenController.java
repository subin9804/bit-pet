package io.bitpet.notification.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.notification.dto.DeviceTokenRegisterRequest;
import io.bitpet.notification.service.DeviceTokenService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Device Token", description = "FCM 디바이스 토큰 등록/해제")
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/device-tokens")
public class DeviceTokenController {

    private final DeviceTokenService deviceTokenService;

    @Operation(summary = "디바이스 토큰 등록", description = "앱 시작·로그인·FCM 토큰 갱신 시 호출 (upsert)")
    @PostMapping
    public ApiResponse<Void> register(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody DeviceTokenRegisterRequest request) {
        deviceTokenService.register(principal.userId(), request);
        return ApiResponse.ok();
    }

    // FCM 토큰에 ':' 등이 포함돼 PathVariable로 받으면 경로 파싱이 흔들려 쿼리 파라미터 사용
    @Operation(summary = "디바이스 토큰 해제", description = "로그아웃 시 호출")
    @DeleteMapping
    public ApiResponse<Void> unregister(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam String deviceToken) {
        deviceTokenService.unregister(deviceToken);
        return ApiResponse.ok();
    }
}
