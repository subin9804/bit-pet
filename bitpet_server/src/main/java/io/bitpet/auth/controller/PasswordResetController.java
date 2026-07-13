package io.bitpet.auth.controller;

import io.bitpet.auth.dto.PasswordResetConfirmDto;
import io.bitpet.auth.dto.PasswordResetRequestDto;
import io.bitpet.auth.dto.PasswordResetResponseDto;
import io.bitpet.auth.dto.PasswordResetVerifyDto;
import io.bitpet.auth.dto.PasswordResetVerifyResponseDto;
import io.bitpet.auth.service.PasswordResetService;
import io.bitpet.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Password Reset", description = "이메일 기반 비밀번호 재설정")
@RestController
@RequestMapping("/api/v1/auth/password-reset")
@RequiredArgsConstructor
public class PasswordResetController {

    private final PasswordResetService passwordResetService;

    @Operation(summary = "비밀번호 재설정 코드 발송 (이메일)")
    @PostMapping("/request")
    public ApiResponse<PasswordResetResponseDto> requestReset(
            @Valid @RequestBody PasswordResetRequestDto request) {
        passwordResetService.requestReset(request.email());
        return ApiResponse.ok(new PasswordResetResponseDto("인증 코드가 발송되었습니다."));
    }

    @Operation(summary = "비밀번호 재설정 코드 인증")
    @PostMapping("/verify")
    public ApiResponse<PasswordResetVerifyResponseDto> verifyCode(
            @Valid @RequestBody PasswordResetVerifyDto request) {
        String token = passwordResetService.verifyCode(request.email(), request.code());
        return ApiResponse.ok(new PasswordResetVerifyResponseDto(token));
    }

    @Operation(summary = "새 비밀번호 설정")
    @PostMapping("/confirm")
    public ApiResponse<PasswordResetResponseDto> confirmReset(
            @Valid @RequestBody PasswordResetConfirmDto request) {
        passwordResetService.confirmReset(request.token(), request.newPassword());
        return ApiResponse.ok(new PasswordResetResponseDto("비밀번호가 변경되었습니다."));
    }
}
