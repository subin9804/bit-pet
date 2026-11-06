package io.bitpet.auth.dto;

/**
 * @param available     가입 가능 (도메인 허용 + 미사용)
 * @param domainAllowed false 면 이미 쓰는 주소가 아니라 받지 않는 도메인이라 막힌 것 — 앱 안내 문구가 다르다
 */
public record EmailCheckResponse(boolean available, boolean domainAllowed) {
}
