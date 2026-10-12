package io.bitpet.record.laying.dto;

import io.bitpet.record.laying.domain.HatchStatus;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;

public record HatchCreateRequest(
        OffsetDateTime hatchedAt,
        @NotNull HatchStatus status,
        /** 알 번호 — 비우면 클러치의 다음 번호가 붙는다 */
        @Min(1) Integer eggIndex,
        String memo
) {}
