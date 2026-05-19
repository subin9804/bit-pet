package io.bitpet.pet.dto;

import java.util.List;

public record GenealogyResponse(
        PetResponse pet,
        List<PetResponse> parents,
        List<PetResponse> children
) {}
