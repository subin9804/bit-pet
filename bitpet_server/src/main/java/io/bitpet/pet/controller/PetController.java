package io.bitpet.pet.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.GenealogyResponse;
import io.bitpet.pet.dto.PetBulkDeleteRequest;
import io.bitpet.pet.dto.PetBulkDeleteResponse;
import io.bitpet.pet.dto.PetCardResponse;
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

@Tag(name = "Pet", description = "개체 관리 CRUD + 관계")
@RestController
@RequestMapping("/api/v1/pets")
@RequiredArgsConstructor
public class PetController {

    private final PetService petService;

    /** POST /api/v1/pets/matings 구 엔드포인트 — 410 Gone 처리 (v5에서 /api/v1/pets/{petId}/matings 로 이전) */
    private static final ApiResponse<Void> MATING_GONE = ApiResponse.fail(
            ErrorCode.MATING_NOT_FOUND,
            "이 엔드포인트는 더 이상 지원되지 않습니다. POST /api/v1/pets/{petId}/matings 를 사용하세요."
    );

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

    @Operation(summary = "일련번호로 공개 개체 조회 (메이팅 파트너 검색용, 검색허용 개체만 반환)")
    @GetMapping("/by-serial")
    public ApiResponse<PetResponse> findBySerial(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam String serialNo) {
        return ApiResponse.ok(petService.findBySerial(serialNo));
    }

    @Operation(summary = "일련번호로 개체 카드 조회 (가계도 부모 선택용). 정확 일치만, 비공개는 404")
    @GetMapping("/by-serial/card")
    public ApiResponse<PetCardResponse> findCardBySerial(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam String serialNo) {
        return ApiResponse.ok(petService.findCardBySerial(principal.userId(), serialNo));
    }

    @Operation(summary = "개체 단건 조회")
    @GetMapping("/{petId}")
    public ApiResponse<PetResponse> get(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(petService.get(principal.userId(), petId));
    }

    @Operation(summary = "남의 개체 공개 조회 (가계도 카드 → 개체 상세). 비공개 개체는 404")
    @GetMapping("/{petId}/public")
    public ApiResponse<PetCardResponse> getPublic(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(petService.getPublicCard(principal.userId(), petId));
    }

    @Operation(summary = "개체 정보 수정 (부분 수정)")
    @PatchMapping("/{petId}")
    public ApiResponse<PetResponse> update(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody PetUpdateRequest request) {
        return ApiResponse.ok(petService.update(principal.userId(), petId, request));
    }

    @Operation(summary = "대표(프로필) 사진 지정 — 갤러리 사진 중 하나")
    @org.springframework.web.bind.annotation.PutMapping("/{petId}/profile-photo/{photoId}")
    public ApiResponse<PetResponse> setProfilePhoto(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @PathVariable Long photoId) {
        return ApiResponse.ok(petService.setProfilePhoto(principal.userId(), petId, photoId));
    }

    @Operation(summary = "개체 삭제 (Soft Delete)")
    @DeleteMapping("/{petId}")
    public ApiResponse<Void> delete(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        petService.delete(principal.userId(), petId);
        return ApiResponse.ok();
    }

    @Operation(summary = "개체 일괄 삭제 (Soft Delete) — 소유자가 아닌 개체가 하나라도 있으면 전체 실패")
    @DeleteMapping
    public ApiResponse<PetBulkDeleteResponse> deleteBulk(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody PetBulkDeleteRequest request) {
        return ApiResponse.ok(petService.deleteAll(principal.userId(), request.petIds()));
    }

    @Operation(summary = "이별하기 — 개체 폐사 처리 (기록 보존, deceasedAt 미지정 시 오늘)")
    @PostMapping("/{petId}/deceased")
    public ApiResponse<PetResponse> markDeceased(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @RequestBody(required = false) java.util.Map<String, String> body) {
        java.time.LocalDate date = body != null && body.get("deceasedAt") != null
                ? java.time.LocalDate.parse(body.get("deceasedAt"))
                : null;
        return ApiResponse.ok(petService.markDeceased(principal.userId(), petId, date));
    }

    @Operation(summary = "이별 취소 — 폐사 표시 해제")
    @DeleteMapping("/{petId}/deceased")
    public ApiResponse<PetResponse> revertDeceased(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(petService.revertDeceased(principal.userId(), petId));
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

    @Operation(summary = "부모-자식 관계 등록")
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
    // Deprecated — 구 메이팅 엔드포인트 (v5에서 410 Gone)
    // -------------------------------------------------------------------------

    /**
     * @deprecated v5에서 410 Gone.
     * 대체: POST /api/v1/pets/{petId}/matings
     */
    @Operation(summary = "⚠️ Deprecated — 410 Gone. POST /api/v1/pets/{petId}/matings 사용")
    @PostMapping("/matings")
    @ResponseStatus(HttpStatus.GONE)
    @Deprecated
    public ApiResponse<Void> addMatingDeprecated(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestBody Object ignored) {
        return MATING_GONE;
    }

    /**
     * @deprecated v5에서 410 Gone.
     * 대체: DELETE /api/v1/matings/{matingId}
     */
    @Operation(summary = "⚠️ Deprecated — 410 Gone. DELETE /api/v1/matings/{matingId} 사용")
    @DeleteMapping("/matings/{matingId}")
    @ResponseStatus(HttpStatus.GONE)
    @Deprecated
    public ApiResponse<Void> deleteMatingDeprecated(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long matingId) {
        return MATING_GONE;
    }
}
