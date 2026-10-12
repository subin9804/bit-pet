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
        /**
         * 야생생물법 신고 여부 'Y'/'N' (선택, 기본 'N'). 두 제도를 따로 받는다 —
         * keeping = 지정관리 야생동물 보관신고(지자체), cites = CITES 양도·양수 신고(유역환경청).
         */
        @Pattern(regexp = "^[YN]$", message = "keepingReportYn은 Y 또는 N이어야 합니다") String keepingReportYn,
        @Pattern(regexp = "^[YN]$", message = "citesReportYn은 Y 또는 N이어야 합니다") String citesReportYn,
        /** 부(♂) 개체 id — 실존 개체면 소유자와 무관하게 걸 수 있다 (가계도 부모 등록 정책) */
        Long fatherPetId,
        /** 모(♀) 개체 id */
        Long motherPetId
) {}
