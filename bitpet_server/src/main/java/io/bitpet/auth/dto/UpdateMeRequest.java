package io.bitpet.auth.dto;

import jakarta.validation.constraints.Size;

/**
 * 내 프로필 수정 — 전달된 필드만 반영(부분 수정).
 * profileImageKey: 프로필 이미지 presign으로 업로드한 S3 key. 빈 문자열이면 제거.
 */
public record UpdateMeRequest(
        @Size(min = 1, max = 50) String nickname,
        String profileImageKey
) {}
