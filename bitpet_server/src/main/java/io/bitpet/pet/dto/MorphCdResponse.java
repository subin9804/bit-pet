package io.bitpet.pet.dto;

import io.bitpet.pet.domain.MorphCd;

public record MorphCdResponse(
        Long id,
        Long speciesId,
        String nameKo,
        String nameEn,
        String aliasList,
        Boolean hasHealthConcern,
        Short displayOrder,
        /** true = 사용자가 직접 입력한 모프(V7). 앱에서 '직접 입력' 배지 표시용. */
        Boolean isUserDefined
) {
    public static MorphCdResponse from(MorphCd m) {
        return new MorphCdResponse(
                m.getId(), m.getSpeciesId(), m.getNameKo(), m.getNameEn(),
                m.getAliasList(), m.getHasHealthConcern(), m.getDisplayOrder(),
                m.getIsUserDefined()
        );
    }
}
