package io.bitpet.community.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.community.dto.BlockedUserResponse;
import io.bitpet.community.service.BlockService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** 사용자 차단. 차단은 차단만 한다 — 운영자에게 아무것도 올라가지 않는다 */
@Tag(name = "Block", description = "사용자 차단")
@RestController
@RequestMapping("/api/v1/blocks")
@RequiredArgsConstructor
public class BlockController {

    private final BlockService blockService;

    @Operation(summary = "차단 목록 (내가 차단한 사람만)")
    @GetMapping
    public ApiResponse<List<BlockedUserResponse>> list(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(blockService.listBlocked(principal.userId()));
    }

    @Operation(summary = "차단", description = "이미 차단한 상대여도 성공으로 응답한다 (연타·재시도 대비)")
    @PostMapping("/{userId}")
    public ApiResponse<Void> block(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long userId) {
        blockService.block(principal.userId(), userId);
        return ApiResponse.ok();
    }

    @Operation(summary = "차단 해제",
            description = "신고로 함께 생긴 차단도 여기서 푼다. 신고 자체는 이력이라 남는다.")
    @DeleteMapping("/{userId}")
    public ApiResponse<Void> unblock(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long userId) {
        blockService.unblock(principal.userId(), userId);
        return ApiResponse.ok();
    }
}
