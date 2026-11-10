package io.bitpet.auth.dto;

import jakarta.validation.constraints.NotNull;

/** 자녀 계정 커뮤니티 허용 켜기/끄기 (V2). 빠진 요청이 false 로 조용히 통과하지 않게 래퍼로 받는다 */
public record ChildCommunityRequest(@NotNull Boolean enabled) {}
