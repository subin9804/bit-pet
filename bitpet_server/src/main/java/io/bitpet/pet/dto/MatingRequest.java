package io.bitpet.pet.dto;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record MatingRequest(
        @NotNull Long malePetId,
        @NotNull Long femalePetId,
        @NotNull LocalDate matingDate,
        String memo
) {}
