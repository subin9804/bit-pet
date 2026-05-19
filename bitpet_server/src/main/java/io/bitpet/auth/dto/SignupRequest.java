package io.bitpet.auth.dto;

import io.bitpet.common.validation.ValidPassword;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SignupRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(max = 64) @ValidPassword String password,
        @NotBlank @Size(min = 2, max = 30) String nickname
) {}
