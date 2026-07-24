package io.bitpet.auth.controller;

import io.bitpet.auth.dto.EmailCheckResponse;
import io.bitpet.auth.dto.LoginRequest;
import io.bitpet.auth.dto.RefreshRequest;
import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.dto.TokenResponse;
import io.bitpet.auth.dto.UpdateMeRequest;
import io.bitpet.auth.dto.UserResponse;
import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.dto.PresignResponse;
import io.bitpet.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Auth", description = "회원가입 / 로그인 / 토큰 갱신")
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @Operation(summary = "이메일 중복확인")
    @GetMapping("/check-email")
    public ApiResponse<EmailCheckResponse> checkEmail(@RequestParam String email) {
        return ApiResponse.ok(authService.checkEmail(email));
    }

    @Operation(summary = "회원가입 (이메일 + 비밀번호)")
    @PostMapping("/signup")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<UserResponse> signup(@Valid @RequestBody SignupRequest request) {
        return ApiResponse.ok(authService.signup(request));
    }

    @Operation(summary = "로그인 → access + refresh 발급")
    @PostMapping("/login")
    public ApiResponse<TokenResponse> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok(authService.login(request));
    }

    @Operation(summary = "Refresh 토큰으로 access 재발급 (rotation)")
    @PostMapping("/refresh")
    public ApiResponse<TokenResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        return ApiResponse.ok(authService.refresh(request.refreshToken()));
    }

    @Operation(summary = "로그아웃 (refresh 무효화)")
    @DeleteMapping("/logout")
    public ApiResponse<Void> logout(@AuthenticationPrincipal AuthPrincipal principal) {
        authService.logout(principal.userId());
        return ApiResponse.ok();
    }

    @Operation(summary = "내 정보 조회 (앱 재시작 시 프로필 복원용)")
    @GetMapping("/me")
    public ApiResponse<UserResponse> me(@AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(authService.getMe(principal.userId()));
    }

    @Operation(summary = "내 프로필 수정 (닉네임 / 프로필 이미지)")
    @PatchMapping("/me")
    public ApiResponse<UserResponse> updateMe(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody UpdateMeRequest request) {
        return ApiResponse.ok(authService.updateMe(principal.userId(), request));
    }

    @Operation(summary = "프로필 이미지 presigned PUT URL 발급")
    @PostMapping("/me/profile-image/presign")
    public ApiResponse<PresignResponse> presignProfileImage(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam String filename) {
        return ApiResponse.ok(authService.presignProfileImage(principal.userId(), filename));
    }

    @Operation(summary = "회원탈퇴 (Soft Delete + 30일 유예)")
    @DeleteMapping("/withdraw")
    public ApiResponse<Void> withdraw(@AuthenticationPrincipal AuthPrincipal principal) {
        authService.withdraw(principal.userId());
        return ApiResponse.ok();
    }
}
