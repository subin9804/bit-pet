package io.bitpet.photo.dto;

import io.bitpet.photo.domain.PetPhotoDtl;

import java.time.Instant;

public record PetPhotoResponse(
        Long id,
        Long petId,
        String s3Key,
        String viewUrl,
        Integer fileSize,
        String mimeType,
        Integer width,
        Integer height,
        Instant takenAt,
        String caption,
        Instant createdAt
) {
    public static PetPhotoResponse of(PetPhotoDtl photo, String viewUrl) {
        return new PetPhotoResponse(
                photo.getId(), photo.getPetId(), photo.getS3Key(), viewUrl,
                photo.getFileSize(), photo.getMimeType(),
                photo.getWidth(), photo.getHeight(),
                photo.getTakenAt(), photo.getCaption(), photo.getCreatedAt()
        );
    }
}
