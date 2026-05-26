package io.bitpet.photo.dto;

import io.bitpet.photo.domain.EntityType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record PhotoPresignRequest(
        @NotNull EntityType entityType,
        @NotNull Long entityId,
        @NotBlank String fileName,
        String contentType
) {}
