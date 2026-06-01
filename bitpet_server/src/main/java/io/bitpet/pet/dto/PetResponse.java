package io.bitpet.pet.dto;

import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public record PetResponse(
        Long id,
        String serialNo,
        Long userId,
        Long speciesId,
        String speciesNameKo,
        String speciesCategory,
        List<MorphCdResponse> morphs,
        String name,
        PetGender gender,
        String colorCode,
        String description,
        LocalDate breedingDate,
        LocalDate hatchingDate,
        LocalDate adoptionDate,
        Long profilePhotoId,
        Instant createdAt,
        Instant updatedAt
) {
    public static PetResponse from(PetMst pet) {
        List<MorphCdResponse> morphList = pet.getMorphs().stream()
                .map(rls -> MorphCdResponse.from(rls.getMorph()))
                .toList();
        return new PetResponse(
                pet.getId(),
                pet.getSerialNo(),
                pet.getUserId(),
                pet.getSpecies() != null ? pet.getSpecies().getId() : null,
                pet.getSpecies() != null ? pet.getSpecies().getNameKo() : null,
                pet.getSpecies() != null ? pet.getSpecies().getCategory() : null,
                morphList,
                pet.getName(),
                pet.getGender(),
                pet.getColorCode(),
                pet.getDescription(),
                pet.getBreedingDate(),
                pet.getHatchingDate(),
                pet.getAdoptionDate(),
                pet.getProfilePhotoId(),
                pet.getCreatedAt(),
                pet.getUpdatedAt()
        );
    }
}
