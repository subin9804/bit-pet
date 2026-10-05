package io.bitpet.pet.dto;

import io.bitpet.pet.domain.PetGender;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.List;

public record PetUpdateRequest(
        @Size(min = 1, max = 50) String name,
        Long speciesId,
        List<Long> morphIds,
        Long morphId,
        PetGender gender,
        @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "색상 코드는 #RRGGBB 형식이어야 합니다") String colorCode,
        String description,
        LocalDate breedingDate,
        LocalDate hatchingDate,
        String hatchingDatePrecision,
        Boolean hatchingDateApproximate,
        LocalDate adoptionDate,
        @Pattern(regexp = "^[YN]$", message = "privateYn은 Y 또는 N이어야 합니다") String privateYn,

        /**
         * 부모 수정 여부 — <b>이 플래그가 true 일 때만</b> 아래 두 값으로 부모 관계를 갈아끼운다
         * (null 은 "해제"로 해석한다).
         *
         * <p>플래그를 따로 둔 이유: 부분 수정 요청에서 "안 보냄"과 "비워달라"를 id 필드만으로는
         * 구분할 수 없다. 플래그 없이 null 을 해제로 보면 부모 필드를 모르는 경로(오프라인 sync
         * push, 구버전 앱)가 저장할 때마다 가계도가 조용히 지워진다.
         */
        Boolean editParents,
        Long fatherPetId,
        Long motherPetId
) {}
