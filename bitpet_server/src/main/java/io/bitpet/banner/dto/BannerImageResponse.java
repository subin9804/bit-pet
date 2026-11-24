package io.bitpet.banner.dto;

/** 관리 페이지 이미지 업로드 결과 — 키는 폼에 넣고, url 은 미리보기에 쓴다. */
public record BannerImageResponse(String imageKey, String imageUrl) {}
