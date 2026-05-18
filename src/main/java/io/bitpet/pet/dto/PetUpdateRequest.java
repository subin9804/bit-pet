package io.bitpet.pet.dto;

import io.bitpet.pet.domain.PetGender;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record PetUpdateRequest(
        @Size(min = 1, max = 50) String name,
        Long speciesId,
        PetGender gender,
        @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "색상 코드는 #RRGGBB 형식이어야 합니다") String colorCode,
        String environmentMemo,
        LocalDate breedingDate,
        LocalDate hatchingDate,
        LocalDate adoptionDate
) {}
