package io.bitpet.pet.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.pet.dto.MorphCdResponse;
import io.bitpet.pet.dto.MorphCustomCreateRequest;
import io.bitpet.pet.dto.SpeciesCdResponse;
import io.bitpet.pet.repository.SpeciesCdRepository;
import io.bitpet.pet.service.MorphService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Species", description = "종(Species) / 모프(Morph) 마스터 조회")
@RestController
@RequestMapping("/api/v1/species")
@RequiredArgsConstructor
public class SpeciesController {

    private final SpeciesCdRepository speciesRepository;
    private final MorphService morphService;

    @Operation(summary = "종 목록 조회 (subcategory 또는 category 필터 가능)",
            description = "subcategory(G/L/C/S/T/F/N) 우선, 없으면 category(R/A), 둘 다 없으면 전체 반환.")
    @GetMapping
    public ApiResponse<List<SpeciesCdResponse>> list(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String subcategory) {
        List<SpeciesCdResponse> result;
        if (subcategory != null && !subcategory.isBlank()) {
            result = speciesRepository
                    .findAllBySubcategoryAndIsActiveTrueOrderByDisplayOrderAsc(subcategory.toUpperCase())
                    .stream().map(SpeciesCdResponse::from).toList();
        } else if (category != null && !category.isBlank()) {
            result = speciesRepository
                    .findAllByCategoryAndIsActiveTrueOrderByDisplayOrderAsc(category.toUpperCase())
                    .stream().map(SpeciesCdResponse::from).toList();
        } else {
            result = speciesRepository.findAllByIsActiveTrueOrderByDisplayOrderAsc()
                    .stream().map(SpeciesCdResponse::from).toList();
        }
        return ApiResponse.ok(result);
    }

    @Operation(summary = "종별 모프 목록 조회",
            description = "공식 카탈로그 + 본인이 등록한 커스텀 모프. 비로그인 접근이 허용되어 있어 "
                    + "그 경우 공식 카탈로그만 반환된다.")
    @GetMapping("/{speciesId}/morphs")
    public ApiResponse<List<MorphCdResponse>> listMorphs(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long speciesId) {
        Long userId = principal == null ? null : principal.userId();
        return ApiResponse.ok(morphService.listBySpecies(speciesId, userId));
    }

    @Operation(summary = "모프 autocomplete 검색 (name_ko / name_en / alias_list LIKE)")
    @GetMapping("/morphs/autocomplete")
    public ApiResponse<List<MorphCdResponse>> morphAutocomplete(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam Long speciesId,
            @RequestParam String q) {
        Long userId = principal == null ? null : principal.userId();
        return ApiResponse.ok(morphService.autocomplete(speciesId, q, userId));
    }

    @Operation(summary = "커스텀 모프 등록",
            description = "카탈로그에 없는 조합 모프를 직접 등록한다. 같은 종에 같은 이름이 이미 있으면 "
                    + "새로 만들지 않고 기존 모프를 반환한다. 본인에게만 보인다.")
    @PostMapping("/{speciesId}/morphs/custom")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<MorphCdResponse> createCustomMorph(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long speciesId,
            @Valid @RequestBody MorphCustomCreateRequest request) {
        return ApiResponse.ok(morphService.createCustom(speciesId, request.nameKo(), principal.userId()));
    }
}
