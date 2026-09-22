package io.bitpet.photo.dto;

import io.bitpet.photo.domain.EntityType;
import io.bitpet.photo.domain.PhotoDtl;

import java.time.Instant;

public record PhotoResponse(
        Long photoId,
        EntityType entityType,
        Long entityId,
        String url,
        /**
         * 축소본(짧은 변 512px 기준) URL. <b>null 이면 썸네일이 없다</b> — 기존 사진과 구버전 앱이
         * 올린 사진. 앱은 {@code thumbnailUrl ?? url} 로 폴백한다.
         */
        String thumbnailUrl,
        Integer fileSize,
        String mimeType,
        Integer width,
        Integer height,
        Instant takenAt,
        String caption,
        Instant createdAt
) {
    public static PhotoResponse of(PhotoDtl photo, String url, String thumbnailUrl) {
        return new PhotoResponse(
                photo.getId(),
                photo.getEntityType(),
                photo.getEntityId(),
                url,
                thumbnailUrl,
                photo.getFileSize(),
                photo.getMimeType(),
                photo.getWidth(),
                photo.getHeight(),
                photo.getTakenAt(),
                photo.getCaption(),
                photo.getCreatedAt()
        );
    }
}
