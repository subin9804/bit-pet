package io.bitpet.record.laying.dto;

import io.bitpet.pet.domain.PetGender;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record RegisterPetRequest(
        @NotBlank String name,
        Long speciesId,
        Long morphId,
        @NotNull PetGender gender,
        LocalDate birthDate,
        String memo
) {}
