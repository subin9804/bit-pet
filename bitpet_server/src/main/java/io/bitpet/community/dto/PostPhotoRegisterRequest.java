package io.bitpet.community.dto;

import jakarta.validation.constraints.NotBlank;

public record PostPhotoRegisterRequest(
        @NotBlank String s3Key,
        int displayOrder,
        Integer width,
        Integer height
) {}
