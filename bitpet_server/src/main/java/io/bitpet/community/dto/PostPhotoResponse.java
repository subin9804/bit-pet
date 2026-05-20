package io.bitpet.community.dto;

import io.bitpet.community.domain.PostPhotoDtl;

public record PostPhotoResponse(
        Long id,
        String viewUrl,
        int displayOrder,
        Integer width,
        Integer height
) {
    public static PostPhotoResponse of(PostPhotoDtl p, String viewUrl) {
        return new PostPhotoResponse(p.getId(), viewUrl, p.getDisplayOrder(), p.getWidth(), p.getHeight());
    }
}
