package io.bitpet.record.laying.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.record.laying.dto.HatchCreateRequest;
import io.bitpet.record.laying.dto.HatchResponse;
import io.bitpet.record.laying.dto.HatchUpdateRequest;
import io.bitpet.record.laying.dto.LayingCreateRequest;
import io.bitpet.record.laying.dto.LayingResponse;
import io.bitpet.record.laying.dto.LayingUpdateRequest;
import io.bitpet.record.laying.dto.RegisterPetRequest;
import io.bitpet.record.laying.service.LayingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
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

import java.time.LocalDate;

@Tag(name = "Laying", description = "산란·해칭 기록 CRUD — /pets/:id/layings")
@RestController
@RequiredArgsConstructor
public class LayingController {

    private final LayingService layingService;

    @Operation(summary = "산란 등록")
    @PostMapping("/api/v1/pets/{petId}/layings")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<LayingResponse> createLaying(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody LayingCreateRequest request) {
        return ApiResponse.ok(layingService.createLaying(petId, principal.userId(), request));
    }

    @Operation(summary = "산란 목록")
    @GetMapping("/api/v1/pets/{petId}/layings")
    public ApiResponse<Page<LayingResponse>> listLayings(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @RequestParam(required = false) Long matingId,
            @RequestParam(required = false) LocalDate from,
            @RequestParam(required = false) LocalDate to,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(layingService.getLayings(
                petId, principal.userId(), matingId, from, to,
                PageRequest.of(page, Math.min(size, 100))));
    }

    @Operation(summary = "산란 단건 조회")
    @GetMapping("/api/v1/layings/{layingId}")
    public ApiResponse<LayingResponse> getLaying(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long layingId) {
        return ApiResponse.ok(layingService.getLaying(layingId, principal.userId()));
    }

    @Operation(summary = "산란 수정")
    @PutMapping("/api/v1/layings/{layingId}")
    public ApiResponse<LayingResponse> updateLaying(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long layingId,
            @Valid @RequestBody LayingUpdateRequest request) {
        return ApiResponse.ok(layingService.updateLaying(layingId, principal.userId(), request));
    }

    @Operation(summary = "산란 삭제")
    @DeleteMapping("/api/v1/layings/{layingId}")
    public ApiResponse<Void> deleteLaying(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long layingId) {
        layingService.deleteLaying(layingId, principal.userId());
        return ApiResponse.ok();
    }

    @Operation(summary = "해칭 추가")
    @PostMapping("/api/v1/layings/{layingId}/hatches")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<HatchResponse> createHatch(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long layingId,
            @Valid @RequestBody HatchCreateRequest request) {
        return ApiResponse.ok(layingService.createHatch(layingId, principal.userId(), request));
    }

    @Operation(summary = "해칭 수정")
    @PutMapping("/api/v1/layings/{layingId}/hatches/{hatchId}")
    public ApiResponse<HatchResponse> updateHatch(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long layingId,
            @PathVariable Long hatchId,
            @Valid @RequestBody HatchUpdateRequest request) {
        return ApiResponse.ok(layingService.updateHatch(layingId, hatchId, principal.userId(), request));
    }

    @Operation(summary = "해칭 삭제")
    @DeleteMapping("/api/v1/layings/{layingId}/hatches/{hatchId}")
    public ApiResponse<Void> deleteHatch(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long layingId,
            @PathVariable Long hatchId) {
        layingService.deleteHatch(layingId, hatchId, principal.userId());
        return ApiResponse.ok();
    }

    @Operation(summary = "⭐ 해칭 → 신규 개체 등록 + 가계도 자동 연결")
    @PostMapping("/api/v1/layings/{layingId}/hatches/{hatchId}/register-pet")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<PetResponse> registerPet(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long layingId,
            @PathVariable Long hatchId,
            @Valid @RequestBody RegisterPetRequest request) {
        return ApiResponse.ok(layingService.registerPet(layingId, hatchId, principal.userId(), request));
    }
}
