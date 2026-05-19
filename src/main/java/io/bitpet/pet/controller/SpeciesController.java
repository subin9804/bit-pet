package io.bitpet.pet.controller;

import io.bitpet.common.response.ApiResponse;
import io.bitpet.pet.dto.MorphCdResponse;
import io.bitpet.pet.dto.SpeciesCdResponse;
import io.bitpet.pet.repository.MorphCdRepository;
import io.bitpet.pet.repository.SpeciesCdRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Species", description = "종(Species) / 모프(Morph) 마스터 조회")
@RestController
@RequestMapping("/api/v1/species")
@RequiredArgsConstructor
public class SpeciesController {

    private final SpeciesCdRepository speciesRepository;
    private final MorphCdRepository morphRepository;

    @Operation(summary = "종 목록 조회 (category 필터 가능)")
    @GetMapping
    public ApiResponse<List<SpeciesCdResponse>> list(
            @RequestParam(required = false) String category) {
        List<SpeciesCdResponse> result = category != null && !category.isBlank()
                ? speciesRepository.findAllByCategoryAndIsActiveTrueOrderByDisplayOrderAsc(category)
                        .stream().map(SpeciesCdResponse::from).toList()
                : speciesRepository.findAllByIsActiveTrueOrderByDisplayOrderAsc()
                        .stream().map(SpeciesCdResponse::from).toList();
        return ApiResponse.ok(result);
    }

    @Operation(summary = "종별 모프 목록 조회")
    @GetMapping("/{speciesId}/morphs")
    public ApiResponse<List<MorphCdResponse>> listMorphs(@PathVariable Long speciesId) {
        List<MorphCdResponse> result = morphRepository
                .findAllBySpeciesIdAndIsActiveTrueOrderByDisplayOrderAsc(speciesId)
                .stream().map(MorphCdResponse::from).toList();
        return ApiResponse.ok(result);
    }
}
