package io.bitpet.pet.dto;

import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;

import java.time.Instant;
import java.time.LocalDate;

public record PetResponse(
        Long id,
        String serialNo,
        Long userId,
        Long speciesId,
        String speciesNameKo,
        String name,
        PetGender gender,
        String colorCode,
        String environmentMemo,
        LocalDate breedingDate,
        LocalDate hatchingDate,
        LocalDate adoptionDate,
        Long profilePhotoId,
        Instant createdAt,
        Instant updatedAt
) {
    public static PetResponse from(PetMst pet) {
        return new PetResponse(
                pet.getId(),
                pet.getSerialNo(),
                pet.getUserId(),
                pet.getSpecies() != null ? pet.getSpecies().getId() : null,
                pet.getSpecies() != null ? pet.getSpecies().getNameKo() : null,
                pet.getName(),
                pet.getGender(),
                pet.getColorCode(),
                pet.getEnvironmentMemo(),
                pet.getBreedingDate(),
                pet.getHatchingDate(),
                pet.getAdoptionDate(),
                pet.getProfilePhotoId(),
                pet.getCreatedAt(),
                pet.getUpdatedAt()
        );
    }
}
