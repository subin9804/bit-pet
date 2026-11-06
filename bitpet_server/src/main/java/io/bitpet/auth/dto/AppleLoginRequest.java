package io.bitpet.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 앱 네이티브 Apple 로그인 결과.
 *
 * @param identityToken     Apple 이 서명한 신원 토큰(JWT)
 * @param nonce             앱이 이번 로그인에 만든 원문. 토큰에는 이것의 SHA-256(hex) 이 들어 있다
 * @param authorizationCode 탈퇴 때 Apple 연결을 끊기 위한 refresh 토큰 교환용 (5분 유효, 1회용)
 * @param givenName         처음 로그인할 때만 온다
 * @param familyName        처음 로그인할 때만 온다
 */
public record AppleLoginRequest(
        @NotBlank @Size(max = 4096) String identityToken,
        @NotBlank @Size(min = 16, max = 128) String nonce,
        @Size(max = 512) String authorizationCode,
        @Size(max = 100) String givenName,
        @Size(max = 100) String familyName
) {}
