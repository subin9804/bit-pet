package io.bitpet.sync.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.sync.dto.SyncChangesResponse;
import io.bitpet.sync.dto.SyncPushRequest;
import io.bitpet.sync.dto.SyncPushResponse;
import io.bitpet.sync.service.SyncService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Sync", description = "오프라인 동기화 Pull / Push")
@RestController
@RequestMapping("/api/v1/sync")
@RequiredArgsConstructor
public class SyncController {

    private final SyncService syncService;

    @Operation(summary = "변경사항 Pull (since 커서 이후 변경된 데이터)")
    @GetMapping("/changes")
    public ApiResponse<SyncChangesResponse> pull(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestHeader(value = "X-Client-Id", required = false) String clientId,
            @RequestParam(defaultValue = "0") String since,
            @RequestParam(required = false) List<String> resources,
            @RequestParam(defaultValue = "200") int limit) {
        return ApiResponse.ok(syncService.pull(principal.userId(), clientId, since, resources, limit));
    }

    @Operation(summary = "로컬 변경사항 Push (upsert / delete)")
    @PostMapping("/push")
    public ApiResponse<SyncPushResponse> push(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody SyncPushRequest request) {
        return ApiResponse.ok(syncService.push(principal.userId(), request));
    }
}
