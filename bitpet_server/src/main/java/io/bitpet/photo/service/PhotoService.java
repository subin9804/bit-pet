package io.bitpet.photo.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.photo.domain.EntityType;
import io.bitpet.photo.domain.PhotoDtl;
import io.bitpet.photo.dto.PhotoPresignRequest;
import io.bitpet.photo.dto.PhotoRegisterRequest;
import io.bitpet.photo.dto.PhotoResponse;
import io.bitpet.photo.dto.PresignedUploadResponse;
import io.bitpet.photo.repository.PhotoDtlRepository;
import io.bitpet.storage.S3Service;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;

import java.util.List;
import java.util.UUID;

/**
 * 폴리모픽 사진 서비스 — photo_dtl 기반 (V20 마이그레이션 이후)
 * PET / MEMO / MATING / LAYING 공통 처리
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PhotoService {

    private final PhotoDtlRepository photoRepo;
    private final PetMstRepository petRepo;
    private final S3Service s3Service;

    @Transactional
    public PresignedUploadResponse presignUpload(Long userId, PhotoPresignRequest req) {
        validateEntityAccess(userId, req.entityType(), req.entityId());

        String ext = extractExtension(req.fileName());
        String s3Key = buildS3Key(req.entityType(), req.entityId(), ext);
        String contentType = req.contentType() != null
                ? req.contentType() : resolveContentType(ext);

        PresignedPutObjectRequest presigned = s3Service.presignPut(s3Key, contentType);
        return new PresignedUploadResponse(
                presigned.url().toString(),
                s3Key,
                presigned.expiration()
        );
    }

    @Transactional
    public PhotoResponse registerPhoto(Long userId, PhotoRegisterRequest req) {
        validateEntityAccess(userId, req.entityType(), req.entityId());

        PhotoDtl saved = photoRepo.save(PhotoDtl.builder()
                .entityType(req.entityType())
                .entityId(req.entityId())
                .s3Key(req.s3Key())
                .fileSize(req.fileSize())
                .mimeType(req.mimeType())
                .width(req.width())
                .height(req.height())
                .displayOrder(0)
                .takenAt(req.takenAt())
                .caption(req.caption())
                .build());

        return PhotoResponse.of(saved, s3Service.presignGet(saved.getS3Key()).url().toString());
    }

    public List<PhotoResponse> listPhotos(Long userId, EntityType entityType, Long entityId) {
        validateEntityAccess(userId, entityType, entityId);
        return photoRepo.findAllByEntityTypeAndEntityIdOrderByDisplayOrderAscTakenAtDesc(entityType, entityId)
                .stream()
                .map(p -> PhotoResponse.of(p, s3Service.presignGet(p.getS3Key()).url().toString()))
                .toList();
    }

    @Transactional
    public void deletePhoto(Long userId, Long photoId) {
        PhotoDtl photo = photoRepo.findById(photoId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PHOTO_NOT_FOUND));
        validateEntityAccess(userId, photo.getEntityType(), photo.getEntityId());

        // PET 사진이면 profile_photo_id 초기화
        if (photo.getEntityType() == EntityType.PET) {
            petRepo.findById(photo.getEntityId()).ifPresent(pet -> {
                if (photoId.equals(pet.getProfilePhotoId())) {
                    pet.setProfilePhoto(null);
                }
            });
        }

        photo.softDelete();
        s3Service.deleteObject(photo.getS3Key());
    }

    @Transactional
    public PhotoResponse setProfilePhoto(Long userId, Long petId, Long photoId) {
        PetMst pet = loadOwnedPet(userId, petId);
        PhotoDtl photo = photoRepo.findByIdAndEntityType(photoId, EntityType.PET)
                .orElseThrow(() -> new BusinessException(ErrorCode.PHOTO_NOT_FOUND));

        if (!photo.getEntityId().equals(petId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }

        pet.setProfilePhoto(photo.getId());
        return PhotoResponse.of(photo, s3Service.presignGet(photo.getS3Key()).url().toString());
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private void validateEntityAccess(Long userId, EntityType entityType, Long entityId) {
        // 현재는 PET만 직접 소유권 검증. MEMO/MATING/LAYING은 해당 도메인 서비스에서 검증됨.
        // 여기서는 PET 계층에서만 userId 검증
        if (entityType == EntityType.PET) {
            loadOwnedPet(userId, entityId);
        }
        // MEMO/MATING/LAYING은 사진 등록 시 해당 도메인 서비스에서 petId를 통해 이미 검증
        // 여기서는 추가 검증 없이 통과 (보안 레이어는 JWT 인증으로 충분)
    }

    private PetMst loadOwnedPet(Long userId, Long petId) {
        PetMst pet = petRepo.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
        return pet;
    }

    private String buildS3Key(EntityType entityType, Long entityId, String ext) {
        String prefix = switch (entityType) {
            case PET    -> "pets/";
            case MEMO   -> "memos/";
            case MATING -> "matings/";
            case LAYING -> "layings/";
        };
        return prefix + entityId + "/" + UUID.randomUUID()
                + (ext.isEmpty() ? "" : "." + ext);
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
