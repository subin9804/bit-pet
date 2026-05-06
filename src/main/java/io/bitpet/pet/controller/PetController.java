package io.bitpet.pet.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.dto.PetUpdateRequest;
import io.bitpet.pet.service.PetService;
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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Pet", description = "개체(Pet) CRUD")
@RestController
@RequestMapping("/api/v1/pets")
@RequiredArgsConstructor
public class PetController {

    private final PetService petService;

    @Operation(summary = "내 개체 등록 — 6자리 일련번호 자동 발급")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<PetResponse> create(@AuthenticationPrincipal AuthPrincipal principal,
                                            @Valid @RequestBody PetCreateRequest request) {
        return ApiResponse.ok(petService.create(principal.userId(), request));
    }

    @Operation(summary = "내 개체 목록")
    @GetMapping
    public ApiResponse<List<PetResponse>> list(@AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(petService.listByOwner(principal.userId()));
    }

    @Operation(summary = "내 개체 단건 조회")
    @GetMapping("/{petId}")
    public ApiResponse<PetResponse> get(@AuthenticationPrincipal AuthPrincipal principal,
                                         @PathVariable Long petId) {
        return ApiResponse.ok(petService.get(principal.userId(), petId));
    }

    @Operation(summary = "내 개체 정보 수정 (부분 수정)")
    @PatchMapping("/{petId}")
    public ApiResponse<PetResponse> update(@AuthenticationPrincipal AuthPrincipal principal,
                                            @PathVariable Long petId,
                                            @Valid @RequestBody PetUpdateRequest request) {
        return ApiResponse.ok(petService.update(principal.userId(), petId, request));
    }

    @Operation(summary = "내 개체 삭제")
    @DeleteMapping("/{petId}")
    public ApiResponse<Void> delete(@AuthenticationPrincipal AuthPrincipal principal,
                                     @PathVariable Long petId) {
        petService.delete(principal.userId(), petId);
        return ApiResponse.ok();
    }
}
