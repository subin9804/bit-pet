package io.bitpet.banner.dto;

import io.bitpet.banner.domain.BannerLinkType;

/**
 * 앱 홈에 내려가는 배너 한 장.
 *
 * @param linkValue ROUTE 면 앱 내부 경로('/'로 시작), URL 이면 https 주소, NONE 이면 null
 */
public record HomeBannerResponse(
        Long id,
        String title,
        String body,
        String badge,
        String imageUrl,
        BannerLinkType linkType,
        String linkValue
) {}
