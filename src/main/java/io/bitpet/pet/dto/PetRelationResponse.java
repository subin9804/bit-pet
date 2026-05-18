package io.bitpet.pet.dto;

import io.bitpet.pet.domain.PetRelationRls;
import io.bitpet.pet.domain.RelationType;

public record PetRelationResponse(
        Long id,
        Long parentPetId,
        String parentPetName,
        Long childPetId,
        String childPetName,
        RelationType relationType
) {
    public static PetRelationResponse from(PetRelationRls r) {
        return new PetRelationResponse(
                r.getId(),
                r.getParentPet().getId(),
                r.getParentPet().getName(),
                r.getChildPet().getId(),
                r.getChildPet().getName(),
                r.getRelationType()
        );
    }
}
