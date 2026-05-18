package io.bitpet.pet.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.GenealogyResponse;
import io.bitpet.pet.dto.MatingRequest;
import io.bitpet.pet.dto.MatingResponse;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetRelationRequest;
import io.bitpet.pet.dto.PetRelationResponse;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Pet", description = "개체 관리 CRUD + 관계 + 메이팅")
@RestController
@RequestMapping("/api/v1/pets")
@RequiredArgsConstructor
public class PetController {

    private final PetService petService;

    // -------------------------------------------------------------------------
    // D2: 기본 CRUD
    // -------------------------------------------------------------------------

    @Operation(summary = "개체 등록 (일련번호 자동 발급)")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<PetResponse> create(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody PetCreateRequest request) {
        return ApiResponse.ok(petService.create(principal.userId(), request));
    }

    @Operation(summary = "내 개체 목록")
    @GetMapping
    public ApiResponse<List<PetResponse>> list(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(petService.listByOwner(principal.userId()));
    }

    @Operation(summary = "개체 검색 (종·성별·이름 필터)")
    @GetMapping("/search")
    public ApiResponse<List<PetResponse>> search(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam(required = false) Long speciesId,
            @RequestParam(required = false) PetGender gender,
            @RequestParam(required = false) String name) {
        return ApiResponse.ok(petService.search(principal.userId(), speciesId, gender, name));
    }

    @Operation(summary = "개체 단건 조회")
    @GetMapping("/{petId}")
    public ApiResponse<PetResponse> get(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(petService.get(principal.userId(), petId));
    }

    @Operation(summary = "개체 정보 수정 (부분 수정)")
    @PatchMapping("/{petId}")
    public ApiResponse<PetResponse> update(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody PetUpdateRequest request) {
        return ApiResponse.ok(petService.update(principal.userId(), petId, request));
    }

    @Operation(summary = "개체 삭제 (Soft Delete)")
    @DeleteMapping("/{petId}")
    public ApiResponse<Void> delete(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        petService.delete(principal.userId(), petId);
        return ApiResponse.ok();
    }

    // -------------------------------------------------------------------------
    // D3: 가계도 / 부모-자식 관계
    // -------------------------------------------------------------------------

    @Operation(summary = "개체 가계도 조회 (부모·자식 목록)")
    @GetMapping("/{petId}/genealogy")
    public ApiResponse<GenealogyResponse> getGenealogy(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(petService.getGenealogy(principal.userId(), petId));
    }

    @Operation(summary = "개체 관계 목록 조회")
    @GetMapping("/{petId}/relations")
    public ApiResponse<List<PetRelationResponse>> listRelations(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(petService.listRelations(principal.userId(), petId));
    }

    @Operation(summary = "부모-자식 관계 등록 (mating 이후 수동 등록)")
    @PostMapping("/relations")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<PetRelationResponse> addRelation(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody PetRelationRequest request) {
        return ApiResponse.ok(petService.addRelation(principal.userId(), request));
    }

    @Operation(summary = "부모-자식 관계 삭제")
    @DeleteMapping("/relations/{relationId}")
    public ApiResponse<Void> deleteRelation(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long relationId) {
        petService.deleteRelation(principal.userId(), relationId);
        return ApiResponse.ok();
    }

    // -------------------------------------------------------------------------
    // D3: 메이팅 기록
    // -------------------------------------------------------------------------

    @Operation(summary = "메이팅 기록 등록")
    @PostMapping("/matings")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<MatingResponse> addMating(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody MatingRequest request) {
        return ApiResponse.ok(petService.addMating(principal.userId(), request));
    }

    @Operation(summary = "개체별 메이팅 기록 목록")
    @GetMapping("/{petId}/matings")
    public ApiResponse<List<MatingResponse>> listMatings(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(petService.listMatings(principal.userId(), petId));
    }

    @Operation(summary = "메이팅 기록 삭제")
    @DeleteMapping("/matings/{matingId}")
    public ApiResponse<Void> deleteMating(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long matingId) {
        petService.deleteMating(principal.userId(), matingId);
        return ApiResponse.ok();
    }
}
