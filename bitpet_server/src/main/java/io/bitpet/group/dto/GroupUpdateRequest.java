package io.bitpet.group.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record GroupUpdateRequest(
        @NotBlank @Size(max = 100) String name
) {}
