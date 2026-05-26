package io.bitpet.photo.dto;

import io.bitpet.photo.domain.EntityType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public record PhotoRegisterRequest(
        @NotNull EntityType entityType,
        @NotNull Long entityId,
        @NotBlank String s3Key,
        Integer fileSize,
        String mimeType,
        Integer width,
        Integer height,
        Instant takenAt,
        String caption
) {}
