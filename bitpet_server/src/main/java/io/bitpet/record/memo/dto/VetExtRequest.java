package io.bitpet.record.memo.dto;

import jakarta.validation.constraints.Min;

import java.time.OffsetDateTime;

public record VetExtRequest(
        String clinicName,
        @Min(0) Integer cost,
        OffsetDateTime nextVisitAt
) {}
