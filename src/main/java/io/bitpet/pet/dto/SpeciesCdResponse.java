package io.bitpet.pet.dto;

import io.bitpet.pet.domain.SpeciesCd;

public record SpeciesCdResponse(
        Long id,
        String code,
        String category,
        String subcategory,
        String nameKo,
        String nameEn,
        String scientificName,
        int displayOrder
) {
    public static SpeciesCdResponse from(SpeciesCd s) {
        return new SpeciesCdResponse(
                s.getId(), s.getCode(), s.getCategory(), s.getSubcategory(),
                s.getNameKo(), s.getNameEn(), s.getScientificName(), s.getDisplayOrder()
        );
    }
}
