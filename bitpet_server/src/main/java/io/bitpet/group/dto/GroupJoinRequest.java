package io.bitpet.group.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record GroupJoinRequest(
        @NotBlank @Size(min = 6, max = 6) String inviteCode
) {}
