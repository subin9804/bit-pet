package io.bitpet.photo.dto;

import java.time.Instant;

public record PresignedUploadResponse(
        String presignedUrl,
        String s3Key,
        Instant expiresAt
) {}
