package io.bitpet.auth.controller;

import io.bitpet.auth.dto.ChildCreateRequest;
import io.bitpet.auth.dto.ChildResponse;
import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.auth.service.GuardianService;
import io.bitpet.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 보호자(법정대리인) 경로 (V12).
 *
 * <p>전부 <b>로그인한 보호자 본인</b> 기준으로 동작한다. 경로에 보호자 id 를 받지 않는 이유는
 * 받는 순간 "남의 보호자 행세"를 막는 검증을 모든 메서드가 각자 해야 하기 때문이다.
 */
@Tag(name = "Guardian", description = "자녀(만 14세 미만) 계정 생성·조회")
@RestController
@RequestMapping("/api/v1/guardian")
@RequiredArgsConstructor
public class GuardianController {

    private final GuardianService guardianService;

    @Operation(summary = "자녀 계정 만들기 (법정대리인 동의 포함)")
    @PostMapping("/children")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ChildResponse> createChild(@AuthenticationPrincipal AuthPrincipal principal,
                                                  @Valid @RequestBody ChildCreateRequest request) {
        return ApiResponse.ok(guardianService.createChild(principal.userId(), request));
    }

    @Operation(summary = "내 자녀 계정 목록")
    @GetMapping("/children")
    public ApiResponse<List<ChildResponse>> listChildren(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(guardianService.listChildren(principal.userId()));
    }

    @Operation(summary = "자녀 계정 삭제 (일반 탈퇴와 같은 처리)")
    @DeleteMapping("/children/{childId}")
    public ApiResponse<Void> deleteChild(@AuthenticationPrincipal AuthPrincipal principal,
                                         @PathVariable Long childId) {
        guardianService.deleteChild(principal.userId(), childId);
        return ApiResponse.ok(null);
    }
}
