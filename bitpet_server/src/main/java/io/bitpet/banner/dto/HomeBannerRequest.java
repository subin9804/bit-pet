package io.bitpet.banner.dto;

import io.bitpet.banner.domain.BannerLinkType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

/** 배너 등록·수정 — 항상 전체 칸을 보낸다. 링크 값 형식 검증은 서비스에서. */
public record HomeBannerRequest(
        @NotBlank @Size(max = 40) String title,
        @Size(max = 60) String body,
        @Size(max = 10) String badge,
        @Size(max = 300) String imageKey,
        @NotNull BannerLinkType linkType,
        @Size(max = 500) String linkValue,
        Instant startAt,
        Instant endAt,
        int sortOrder,
        boolean active
) {}
