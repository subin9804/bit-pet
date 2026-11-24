package io.bitpet.banner.dto;

import io.bitpet.banner.domain.BannerLinkType;

import java.time.Instant;

/** 관리 페이지 목록·편집용 — 앱용과 달리 기간·순서·켜짐·지금 노출 중인지까지 싣는다. */
public record HomeBannerAdminResponse(
        Long id,
        String title,
        String body,
        String badge,
        String imageKey,
        String imageUrl,
        BannerLinkType linkType,
        String linkValue,
        Instant startAt,
        Instant endAt,
        int sortOrder,
        boolean active,
        boolean live
) {}
