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
        String hatchingDatePrecision,
        Boolean hatchingDateApproximate,
        LocalDate adoptionDate,
        Double currentWeightG,
        /** 부(♂) 개체 id — 실존 개체면 소유자와 무관하게 걸 수 있다 (가계도 부모 등록 정책) */
        Long fatherPetId,
        /** 모(♀) 개체 id */
        Long motherPetId
) {}
