package io.bitpet.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** 소셜 로그인 교환 — 리다이렉트로 받은 code + 앱이 로그인 시작 때 만든 verifier. */
public record OAuthExchangeRequest(
        @NotBlank @Size(max = 128) String code,
        @NotBlank @Size(min = 43, max = 128) String verifier
) {}
