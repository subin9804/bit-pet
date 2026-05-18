package io.bitpet.record.dto;

import io.bitpet.record.domain.WeightSource;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;

public record WeightCreateRequest(
        @NotNull @DecimalMin("0.01") BigDecimal weightG,
        @NotNull Instant measuredAt,
        WeightSource source,
        String memo
) {}
