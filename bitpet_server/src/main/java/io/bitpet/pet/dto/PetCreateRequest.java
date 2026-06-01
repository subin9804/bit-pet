package io.bitpet.pet.dto;

import io.bitpet.pet.domain.PetGender;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.List;

public record PetCreateRequest(
        @NotBlank @Size(min = 1, max = 50) String name,
        Long speciesId,
        List<Long> morphIds,
        PetGender gender,
        @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "색상 코드는 #RRGGBB 형식이어야 합니다") String colorCode,
        String description,
        LocalDate breedingDate,
        LocalDate hatchingDate,
        LocalDate adoptionDate
) {}
