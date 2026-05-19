package io.bitpet.photo.dto;

import jakarta.validation.constraints.NotBlank;

import java.time.Instant;

public record PhotoUploadCompleteRequest(
        @NotBlank String s3Key,
        Integer fileSize,
        String mimeType,
        Integer width,
        Integer height,
        Instant takenAt,
        String caption
) {}
