package io.bitpet.record.laying.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record LayingNoteRequest(
        @NotNull LocalDate notedAt,
        @NotBlank @Size(max = 500) String content
) {}
