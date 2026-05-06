package io.bitpet.pet.dto;

import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetSpecies;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record PetCreateRequest(
        @NotBlank @Size(min = 1, max = 50) String name,
        @NotNull PetSpecies species,
        @Size(max = 50) String breed,
        LocalDate birthDate,
        PetGender gender
) {}
