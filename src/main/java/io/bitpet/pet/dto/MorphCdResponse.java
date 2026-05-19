package io.bitpet.pet.dto;

import io.bitpet.pet.domain.MorphCd;

public record MorphCdResponse(
        Long id,
        Long speciesId,
        String nameKo,
        String nameEn,
        Short displayOrder
) {
    public static MorphCdResponse from(MorphCd m) {
        return new MorphCdResponse(
                m.getId(), m.getSpeciesId(), m.getNameKo(), m.getNameEn(), m.getDisplayOrder()
        );
    }
}
