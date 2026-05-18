package io.bitpet.record.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.record.dto.FeedingCreateRequest;
import io.bitpet.record.dto.FeedingResponse;
import io.bitpet.record.dto.FeedingUpdateRequest;
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

@Tag(name = "Feeding", description = "급여 기록 CRUD")
@RestController
@RequiredArgsConstructor
public class FeedingController {

    private final RecordService recordService;

    @Operation(summary = "급여 기록 목록")
    @GetMapping("/api/v1/pets/{petId}/feedings")
    public ApiResponse<List<FeedingResponse>> list(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(recordService.listFeedings(principal.userId(), petId));
    }

    @Operation(summary = "급여 기록 등록")
    @PostMapping("/api/v1/pets/{petId}/feedings")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<FeedingResponse> create(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody FeedingCreateRequest request) {
        return ApiResponse.ok(recordService.addFeeding(principal.userId(), petId, request));
    }

    @Operation(summary = "급여 기록 수정")
    @PatchMapping("/api/v1/feedings/{feedingId}")
    public ApiResponse<FeedingResponse> update(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long feedingId,
            @Valid @RequestBody FeedingUpdateRequest request) {
        return ApiResponse.ok(recordService.updateFeeding(principal.userId(), feedingId, request));
    }

    @Operation(summary = "급여 기록 삭제")
    @DeleteMapping("/api/v1/feedings/{feedingId}")
    public ApiResponse<Void> delete(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long feedingId) {
        recordService.deleteFeeding(principal.userId(), feedingId);
        return ApiResponse.ok();
    }
}
