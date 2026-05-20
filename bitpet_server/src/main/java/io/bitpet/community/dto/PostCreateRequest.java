package io.bitpet.community.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record PostCreateRequest(
        @NotNull Long categoryId,
        @NotBlank @Size(max = 200) String title,
        @NotBlank String content
) {}
