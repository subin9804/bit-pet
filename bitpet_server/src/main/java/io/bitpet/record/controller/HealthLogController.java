package io.bitpet.record.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.record.dto.HealthLogCreateRequest;
import io.bitpet.record.dto.HealthLogResponse;
import io.bitpet.record.dto.HealthLogUpdateRequest;
import io.bitpet.record.service.RecordService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "HealthLog", description = "건강 기록 CRUD — /pets/:id/health-logs")
@RestController
@RequiredArgsConstructor
public class HealthLogController {

    private final RecordService recordService;

    @Operation(summary = "건강 기록 목록")
    @GetMapping("/api/v1/pets/{petId}/health-logs")
    public ApiResponse<List<HealthLogResponse>> list(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(recordService.listHealthLogs(principal.userId(), petId));
    }

    @Operation(summary = "건강 기록 등록")
    @PostMapping("/api/v1/pets/{petId}/health-logs")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<HealthLogResponse> create(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody HealthLogCreateRequest request) {
        return ApiResponse.ok(recordService.addHealthLog(principal.userId(), petId, request));
    }

    @Operation(summary = "건강 기록 수정")
    @PatchMapping("/api/v1/health-logs/{logId}")
    public ApiResponse<HealthLogResponse> update(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long logId,
            @Valid @RequestBody HealthLogUpdateRequest request) {
        return ApiResponse.ok(recordService.updateHealthLog(principal.userId(), logId, request));
    }

    @Operation(summary = "건강 기록 삭제")
    @DeleteMapping("/api/v1/health-logs/{logId}")
    public ApiResponse<Void> delete(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long logId) {
        recordService.deleteHealthLog(principal.userId(), logId);
        return ApiResponse.ok();
    }
}
