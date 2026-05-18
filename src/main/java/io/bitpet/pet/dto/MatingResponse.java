package io.bitpet.pet.dto;

import io.bitpet.pet.domain.MatingRls;

import java.time.LocalDate;

public record MatingResponse(
        Long id,
        Long malePetId,
        String malePetName,
        Long femalePetId,
        String femalePetName,
        LocalDate matingDate,
        String memo
) {
    public static MatingResponse from(MatingRls m) {
        return new MatingResponse(
                m.getId(),
                m.getMalePet().getId(),
                m.getMalePet().getName(),
                m.getFemalePet().getId(),
                m.getFemalePet().getName(),
                m.getMatingDate(),
                m.getMemo()
        );
    }
}
