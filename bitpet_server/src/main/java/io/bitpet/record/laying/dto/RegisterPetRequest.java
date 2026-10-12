package io.bitpet.record.laying.dto;

import io.bitpet.pet.domain.PetGender;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 부화한 알을 개체로 올릴 때 받는 값.
 *
 * <p>등록 시트는 이름·성별만 받는다. 나머지는 모두 선택이고, 비우면 클러치가 아는 값으로
 * 채운다(종은 어미와 같고, 해칭일은 그 알의 부화일). 모프·사진·몸무게는 '자세히 입력'에서만
 * 쓰는 값이라 없어도 등록이 끝난다.
 */
public record RegisterPetRequest(
        @NotBlank String name,
        Long speciesId,
        Long morphId,
        @NotNull PetGender gender,
        LocalDate birthDate,
        /** 첫 몸무게(g) — 보내면 해칭일자로 체중 기록 한 건이 함께 생긴다 */
        @DecimalMin("0.01") BigDecimal weightG,
        String memo
) {}
