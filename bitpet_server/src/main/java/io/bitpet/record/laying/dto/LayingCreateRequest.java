package io.bitpet.record.laying.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public record LayingCreateRequest(
        Long matingId,
        @NotNull OffsetDateTime laidAt,
        @NotNull @Min(1) Integer eggCountTotal,
        @Min(0) Integer eggCountFertile,
        BigDecimal incubationTemp,
        BigDecimal incubationHumidity,
        String memo
) {}
