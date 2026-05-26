package io.bitpet.record.memo.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;
import java.util.List;

public record MemoUpdateRequest(
        @NotBlank String content,
        @NotNull OffsetDateTime loggedAt,
        List<String> tags,
        VetExtRequest vetExt
) {}
