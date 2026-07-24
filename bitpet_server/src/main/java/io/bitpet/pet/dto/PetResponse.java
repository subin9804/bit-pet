package io.bitpet.pet.dto;

import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.domain.PetRelationRls;
import io.bitpet.pet.domain.RelationType;

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
        String hatchingDatePrecision,
        Boolean hatchingDateApproximate,
        LocalDate adoptionDate,
        Long profilePhotoId,
        String privateYn,
        LocalDate deceasedAt,
        Double latestWeightG,
        Long fatherRelationId,
        Long fatherId,
        String fatherName,
        Long motherRelationId,
        Long motherId,
        String motherName,
        String profileImageUrl,
        Instant createdAt,
        Instant updatedAt
) {
    public static PetResponse from(PetMst pet) {
        return from(pet, null, List.of());
    }

    public static PetResponse from(PetMst pet, Double latestWeightG) {
        return from(pet, latestWeightG, List.of());
    }

    public static PetResponse from(PetMst pet, Double latestWeightG, List<PetRelationRls> parentRelations) {
        return from(pet, latestWeightG, parentRelations, null);
    }

    public static PetResponse from(PetMst pet, Double latestWeightG,
                                   List<PetRelationRls> parentRelations, String profileImageUrl) {
        Long fatherRelId = null; Long fatherId = null; String fatherName = null;
        Long motherRelId = null; Long motherId = null; String motherName = null;
        for (PetRelationRls r : parentRelations) {
            if (r.getRelationType() == RelationType.FATHER) {
                fatherRelId = r.getId();
                fatherId    = r.getParentPet().getId();
                fatherName  = r.getParentPet().getName();
            } else if (r.getRelationType() == RelationType.MOTHER) {
                motherRelId = r.getId();
                motherId    = r.getParentPet().getId();
                motherName  = r.getParentPet().getName();
            }
        }

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
                pet.getHatchingDatePrecision() != null ? pet.getHatchingDatePrecision() : "DAY",
                pet.getHatchingDateApproximate() != null ? pet.getHatchingDateApproximate() : false,
                pet.getAdoptionDate(),
                pet.getProfilePhotoId(),
                pet.getPrivateYn(),
                pet.getDeceasedAt(),
                latestWeightG,
                fatherRelId, fatherId, fatherName,
                motherRelId, motherId, motherName,
                profileImageUrl,
                pet.getCreatedAt(),
                pet.getUpdatedAt()
        );
    }
}
