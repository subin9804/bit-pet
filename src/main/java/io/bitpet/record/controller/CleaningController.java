package io.bitpet.record.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.record.dto.CleaningCreateRequest;
import io.bitpet.record.dto.CleaningResponse;
import io.bitpet.record.dto.CleaningUpdateRequest;
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

@Tag(name = "Cleaning", description = "청소 기록 CRUD")
@RestController
@RequiredArgsConstructor
public class CleaningController {

    private final RecordService recordService;

    @Operation(summary = "청소 기록 목록")
    @GetMapping("/api/v1/pets/{petId}/cleanings")
    public ApiResponse<List<CleaningResponse>> list(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(recordService.listCleanings(principal.userId(), petId));
    }

    @Operation(summary = "청소 기록 등록")
    @PostMapping("/api/v1/pets/{petId}/cleanings")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<CleaningResponse> create(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody CleaningCreateRequest request) {
        return ApiResponse.ok(recordService.addCleaning(principal.userId(), petId, request));
    }

    @Operation(summary = "청소 기록 수정")
    @PatchMapping("/api/v1/cleanings/{cleaningId}")
    public ApiResponse<CleaningResponse> update(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long cleaningId,
            @Valid @RequestBody CleaningUpdateRequest request) {
        return ApiResponse.ok(recordService.updateCleaning(principal.userId(), cleaningId, request));
    }

    @Operation(summary = "청소 기록 삭제")
    @DeleteMapping("/api/v1/cleanings/{cleaningId}")
    public ApiResponse<Void> delete(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long cleaningId) {
        recordService.deleteCleaning(principal.userId(), cleaningId);
        return ApiResponse.ok();
    }
}
