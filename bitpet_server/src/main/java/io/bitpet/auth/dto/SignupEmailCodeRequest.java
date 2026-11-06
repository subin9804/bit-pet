package io.bitpet.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record SignupEmailCodeRequest(
        @NotBlank @Email String email
) {}
