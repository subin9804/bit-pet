package io.bitpet.pet.dto;

import io.bitpet.pet.domain.RelationType;
import jakarta.validation.constraints.NotNull;

public record PetRelationRequest(
        @NotNull Long parentPetId,
        @NotNull Long childPetId,
        @NotNull RelationType relationType
) {}
