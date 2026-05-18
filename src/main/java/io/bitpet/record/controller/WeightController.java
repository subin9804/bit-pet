package io.bitpet.record.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.record.dto.WeightCreateRequest;
import io.bitpet.record.dto.WeightResponse;
import io.bitpet.record.service.RecordService;
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
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Weight", description = "체중 기록 CRUD")
@RestController
@RequiredArgsConstructor
public class WeightController {

    private final RecordService recordService;

    @Operation(summary = "체중 이력 조회")
    @GetMapping("/api/v1/pets/{petId}/weights")
    public ApiResponse<List<WeightResponse>> list(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(recordService.listWeights(principal.userId(), petId));
    }

    @Operation(summary = "체중 입력")
    @PostMapping("/api/v1/pets/{petId}/weights")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<WeightResponse> create(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody WeightCreateRequest request) {
        return ApiResponse.ok(recordService.addWeight(principal.userId(), petId, request));
    }

    @Operation(summary = "체중 삭제")
    @DeleteMapping("/api/v1/weights/{weightId}")
    public ApiResponse<Void> delete(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long weightId) {
        recordService.deleteWeight(principal.userId(), weightId);
        return ApiResponse.ok();
    }
}
