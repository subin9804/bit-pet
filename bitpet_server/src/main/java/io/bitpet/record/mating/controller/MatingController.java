package io.bitpet.record.mating.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.record.mating.dto.MatingCreateRequest;
import io.bitpet.record.mating.dto.MatingListResponse;
import io.bitpet.record.mating.dto.MatingResponse;
import io.bitpet.record.mating.dto.MatingUpdateRequest;
import io.bitpet.record.mating.service.MatingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Mating", description = "메이팅 기록 CRUD — /pets/:id/matings")
@RestController
@RequiredArgsConstructor
public class MatingController {

    private final MatingService matingService;

    @Operation(summary = "메이팅 등록")
    @PostMapping("/api/v1/pets/{petId}/matings")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<MatingResponse> create(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody MatingCreateRequest request) {
        return ApiResponse.ok(matingService.createMating(petId, principal.userId(), request));
    }

    @Operation(summary = "메이팅 목록 조회")
    @GetMapping("/api/v1/pets/{petId}/matings")
    public ApiResponse<MatingListResponse> list(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @RequestParam(required = false) String seasonLabel,
            @RequestParam(required = false) Boolean isSuccessful,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(matingService.getMatings(
                petId, principal.userId(), seasonLabel, isSuccessful,
                PageRequest.of(page, Math.min(size, 100))));
    }

    @Operation(summary = "메이팅 단건 조회")
    @GetMapping("/api/v1/matings/{matingId}")
    public ApiResponse<MatingResponse> get(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long matingId) {
        return ApiResponse.ok(matingService.getMating(matingId, principal.userId()));
    }

    @Operation(summary = "메이팅 수정")
    @PutMapping("/api/v1/matings/{matingId}")
    public ApiResponse<MatingResponse> update(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long matingId,
            @Valid @RequestBody MatingUpdateRequest request) {
        return ApiResponse.ok(matingService.updateMating(matingId, principal.userId(), request));
    }

    @Operation(summary = "메이팅 삭제")
    @DeleteMapping("/api/v1/matings/{matingId}")
    public ApiResponse<Void> delete(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long matingId) {
        matingService.deleteMating(matingId, principal.userId());
        return ApiResponse.ok();
    }
}
