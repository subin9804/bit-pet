package io.bitpet.record.mating.dto;

import io.bitpet.pet.domain.PetMst;
import io.bitpet.record.mating.domain.MatingDtl;

import java.time.Instant;

public record MatingResponse(
        Long matingId,
        Long petIdMale,
        Long petIdFemale,
        PetSummaryDto petMaleSummary,
        PetSummaryDto petFemaleSummary,
        String externalPartnerText,
        Instant triedAt,
        Integer durationMinutes,
        Boolean isSuccessful,
        String seasonLabel,
        String memo,
        Instant createdAt,
        Instant updatedAt
) {
    public static MatingResponse of(MatingDtl mating, PetMst malePet, PetMst femalePet) {
        return new MatingResponse(
                mating.getId(),
                mating.getMalePetId(),
                mating.getFemalePetId(),
                PetSummaryDto.from(malePet),
                PetSummaryDto.from(femalePet),
                mating.getExternalPartnerText(),
                mating.getTriedAt(),
                mating.getDurationMinutes(),
                mating.getIsSuccessful(),
                mating.getSeasonLabel(),
                mating.getMemo(),
                mating.getCreatedAt(),
                mating.getUpdatedAt()
        );
    }
}
