package io.bitpet.photo.dto;

import io.bitpet.photo.domain.EntityType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public record PhotoRegisterRequest(
        @NotNull EntityType entityType,
        @NotNull Long entityId,
        @NotBlank String s3Key,
        /** presign 이 내려준 썸네일 키. 앱이 축소본을 올리지 못했으면 null — 원본으로 폴백한다. */
        String thumbS3Key,
        Integer fileSize,
        String mimeType,
        Integer width,
        Integer height,
        Instant takenAt,
        String caption
) {}
