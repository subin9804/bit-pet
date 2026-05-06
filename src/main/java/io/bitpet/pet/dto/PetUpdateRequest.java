package io.bitpet.pet.dto;

import io.bitpet.pet.domain.PetGender;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record PetUpdateRequest(
        @Size(min = 1, max = 50) String name,
        @Size(max = 50) String breed,
        LocalDate birthDate,
        PetGender gender
) {}
