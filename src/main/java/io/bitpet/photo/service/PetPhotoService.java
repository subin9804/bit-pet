package io.bitpet.photo.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.photo.domain.PetPhotoDtl;
import io.bitpet.photo.dto.PetPhotoResponse;
import io.bitpet.photo.dto.PhotoUploadCompleteRequest;
import io.bitpet.photo.dto.PresignedUploadResponse;
import io.bitpet.photo.repository.PetPhotoDtlRepository;
import io.bitpet.storage.S3Service;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PetPhotoService {

    private final PetMstRepository petRepository;
    private final PetPhotoDtlRepository photoRepository;
    private final S3Service s3Service;

    public PresignedUploadResponse generatePresignedUrl(Long userId, Long petId, String filename) {
        verifyPetOwnership(userId, petId);

        String ext = extractExtension(filename);
        String s3Key = "pets/" + petId + "/" + UUID.randomUUID() + (ext.isEmpty() ? "" : "." + ext);
        String contentType = resolveContentType(ext);

        PresignedPutObjectRequest presigned = s3Service.presignPut(s3Key, contentType);
        return new PresignedUploadResponse(
                presigned.url().toString(),
                s3Key,
                presigned.expiration()
        );
    }

    @Transactional
    public PetPhotoResponse registerPhoto(Long userId, Long petId, PhotoUploadCompleteRequest req) {
        verifyPetOwnership(userId, petId);

        PetPhotoDtl saved = photoRepository.save(PetPhotoDtl.builder()
                .petId(petId)
                .s3Key(req.s3Key())
                .fileSize(req.fileSize())
                .mimeType(req.mimeType())
                .width(req.width())
                .height(req.height())
                .takenAt(req.takenAt())
                .caption(req.caption())
                .build());

        return PetPhotoResponse.of(saved, s3Service.presignGet(saved.getS3Key()).url().toString());
    }

    public List<PetPhotoResponse> listPhotos(Long userId, Long petId) {
        verifyPetOwnership(userId, petId);
        return photoRepository.findAllByPetIdOrderByTakenAtDesc(petId)
                .stream()
                .map(p -> PetPhotoResponse.of(p, s3Service.presignGet(p.getS3Key()).url().toString()))
                .toList();
    }

    @Transactional
    public void deletePhoto(Long userId, Long petId, Long photoId) {
        verifyPetOwnership(userId, petId);
        PetPhotoDtl photo = findPhotoOfPet(photoId, petId);

        // 해당 사진이 프로필 사진이면 pet_mst.profile_photo_id 초기화
        PetMst pet = petRepository.findById(petId).orElseThrow();
        if (photoId.equals(pet.getProfilePhotoId())) {
            pet.setProfilePhoto(null);
        }

        photoRepository.delete(photo);
        s3Service.deleteObject(photo.getS3Key());
    }

    @Transactional
    public PetPhotoResponse setProfilePhoto(Long userId, Long petId, Long photoId) {
        verifyPetOwnership(userId, petId);
        PetPhotoDtl photo = findPhotoOfPet(photoId, petId);

        PetMst pet = petRepository.findById(petId).orElseThrow();
        pet.setProfilePhoto(photo.getId());

        return PetPhotoResponse.of(photo, s3Service.presignGet(photo.getS3Key()).url().toString());
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private void verifyPetOwnership(Long userId, Long petId) {
        PetMst pet = petRepository.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
    }

    private PetPhotoDtl findPhotoOfPet(Long photoId, Long petId) {
        PetPhotoDtl photo = photoRepository.findById(photoId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PHOTO_NOT_FOUND));
        if (!photo.getPetId().equals(petId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
        return photo;
    }

    private static String extractExtension(String filename) {
        if (filename == null || !filename.contains(".")) return "";
        return filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
    }

    private static String resolveContentType(String ext) {
        return switch (ext) {
            case "jpg", "jpeg" -> "image/jpeg";
            case "png"         -> "image/png";
            case "webp"        -> "image/webp";
            case "heic"        -> "image/heic";
            default            -> "application/octet-stream";
        };
    }
}
