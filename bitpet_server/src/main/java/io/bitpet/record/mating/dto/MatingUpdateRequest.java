package io.bitpet.record.mating.dto;

import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;

public record MatingUpdateRequest(
        Long petIdMale,
        Long petIdFemale,
        String externalPartnerText,
        @NotNull OffsetDateTime triedAt,
        Integer durationMinutes,
        Boolean isSuccessful,
        String seasonLabel,
        String memo
) {}
