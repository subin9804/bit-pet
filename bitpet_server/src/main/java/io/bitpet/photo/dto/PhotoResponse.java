package io.bitpet.photo.dto;

import io.bitpet.photo.domain.EntityType;
import io.bitpet.photo.domain.PhotoDtl;

import java.time.Instant;

public record PhotoResponse(
        Long photoId,
        EntityType entityType,
        Long entityId,
        String url,
        Integer fileSize,
        String mimeType,
        Integer width,
        Integer height,
        Instant takenAt,
        String caption,
        Instant createdAt
) {
    public static PhotoResponse of(PhotoDtl photo, String url) {
        return new PhotoResponse(
                photo.getId(),
                photo.getEntityType(),
                photo.getEntityId(),
                url,
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
