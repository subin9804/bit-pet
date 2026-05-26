package io.bitpet.record.mating.dto;

import io.bitpet.pet.domain.PetMst;

public record PetSummaryDto(
        Long petId,
        String name,
        String thumbnailUrl
) {
    public static PetSummaryDto from(PetMst pet) {
        if (pet == null) return null;
        return new PetSummaryDto(pet.getId(), pet.getName(), null);
    }
}
