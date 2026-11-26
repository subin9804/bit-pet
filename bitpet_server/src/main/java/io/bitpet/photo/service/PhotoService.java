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
import io.bitpet.record.laying.repository.LayingDtlRepository;
import io.bitpet.record.mating.domain.MatingDtl;
import io.bitpet.record.mating.repository.MatingDtlRepository;
import io.bitpet.record.memo.repository.MemoDtlRepository;
import io.bitpet.storage.S3Service;
import io.bitpet.storage.UploadKeys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;

import java.util.List;

/**
 * 폴리모픽 사진 서비스 — photo_dtl 기반 (V20 마이그레이션 이후)
 * PET / MEMO / MATING / LAYING 공통 처리
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PhotoService {

    /**
     * 썸네일은 <b>JPEG 고정</b>이다. 앱이 만드는 축소본이라 플랫폼마다 되는 포맷이 달라서는
     * 안 되는데(WebP 인코딩은 Android 만 된다) 원본 포맷을 따라가면 HEIC 썸네일 같은 게 섞인다.
     */
    private static final String THUMB_SUFFIX = "_thumb.jpg";
    private static final String THUMB_CONTENT_TYPE = "image/jpeg";

    private final PhotoDtlRepository photoRepo;
    private final PetMstRepository petRepo;
    private final io.bitpet.pet.service.PetKeeperService petKeeper;
    private final MemoDtlRepository memoRepo;
    private final MatingDtlRepository matingRepo;
    private final LayingDtlRepository layingRepo;
    private final S3Service s3Service;

    @Transactional
    public PresignedUploadResponse presignUpload(Long userId, PhotoPresignRequest req) {
        validateEntityAccess(userId, req.entityType(), req.entityId());

        // content-type 은 앱이 보낸 값이 아니라 확장자로 서버가 정한다 (UploadKeys 참고).
        // 앱도 같은 규칙으로 PUT 헤더를 만들어서 서명과 어긋나지 않는다.
        String ext = UploadKeys.extension(req.fileName());
        String s3Key = UploadKeys.newKey(keyPrefix(req.entityType(), req.entityId()), ext);
        String contentType = UploadKeys.contentType(ext);

        PresignedPutObjectRequest presigned = s3Service.presignPut(s3Key, contentType);

        // 썸네일 자리도 같이 서명해 내린다. 앱이 축소본을 만들면 여기에 PUT 하고,
        // 못 만들면 그냥 쓰지 않으면 된다 (서명만 만료될 뿐 S3 에 아무것도 안 생긴다).
        String thumbKey = buildThumbKey(s3Key);
        PresignedPutObjectRequest thumbPresigned = s3Service.presignPut(thumbKey, THUMB_CONTENT_TYPE);

        return new PresignedUploadResponse(
                presigned.url().toString(),
                s3Key,
                thumbPresigned.url().toString(),
                thumbKey,
                presigned.expiration()
        );
    }

    @Transactional
    public PhotoResponse registerPhoto(Long userId, PhotoRegisterRequest req) {
        validateEntityAccess(userId, req.entityType(), req.entityId());
        if (!UploadKeys.isIssued(req.s3Key(), keyPrefix(req.entityType(), req.entityId()))) {
            throw new BusinessException(ErrorCode.PHOTO_KEY_INVALID);
        }

        PhotoDtl saved = photoRepo.save(PhotoDtl.builder()
                .entityType(req.entityType())
                .entityId(req.entityId())
                .s3Key(req.s3Key())
                .thumbS3Key(acceptThumbKey(req.s3Key(), req.thumbS3Key()))
                .fileSize(req.fileSize())
                .mimeType(req.mimeType())
                .width(req.width())
                .height(req.height())
                .displayOrder(0)
                .takenAt(req.takenAt())
                .caption(req.caption())
                .build());

        return toResponse(saved);
    }

    public List<PhotoResponse> listPhotos(Long userId, EntityType entityType, Long entityId) {
        validateEntityAccess(userId, entityType, entityId);
        return photoRepo.findAllByEntityTypeAndEntityIdOrderByDisplayOrderAscCreatedAtDescIdDesc(entityType, entityId)
                .stream()
                .map(this::toResponse)
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
        // 썸네일도 같이 지운다. 빠뜨리면 원본만 사라지고 축소본이 영원히 남는다.
        if (photo.getThumbS3Key() != null) {
            s3Service.deleteObject(photo.getThumbS3Key());
        }
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
        return toResponse(photo);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private PhotoResponse toResponse(PhotoDtl photo) {
        return PhotoResponse.of(
                photo,
                s3Service.presignGet(photo.getS3Key()).url().toString(),
                photo.getThumbS3Key() != null
                        ? s3Service.presignGet(photo.getThumbS3Key()).url().toString()
                        : null);
    }

    /**
     * 앱이 보내온 썸네일 키를 <b>서버 규칙과 대조해</b> 받아들인다.
     *
     * <p>키를 그대로 믿으면 앱이 아무 경로나 적어 보낼 수 있고, 그러면 사진마다 규칙이
     * 갈려 삭제·정리 경로가 썸네일을 찾지 못한다. 규칙과 다르면 <b>거절이 아니라 무시</b>다 —
     * 축소본 하나 때문에 사진 등록 자체를 실패시킬 이유가 없고, 원본은 이미 올라가 있다.
     */
    private static String acceptThumbKey(String s3Key, String thumbS3Key) {
        if (thumbS3Key == null || thumbS3Key.isBlank()) return null;
        return buildThumbKey(s3Key).equals(thumbS3Key) ? thumbS3Key : null;
    }

    /** 원본 키의 확장자만 갈아끼운다 — {@code pets/1/{uuid}.jpg} → {@code pets/1/{uuid}_thumb.jpg}. */
    private static String buildThumbKey(String s3Key) {
        int dot = s3Key.lastIndexOf('.');
        int slash = s3Key.lastIndexOf('/');
        String base = (dot > slash) ? s3Key.substring(0, dot) : s3Key;
        return base + THUMB_SUFFIX;
    }

    /**
     * 사진이 붙는 대상의 사육자인지 — 각 도메인 서비스의 조회 권한과 같은 기준이다.
     * 메모·산란은 그 개체의 사육자, 메이팅은 암수 중 한쪽의 사육자.
     *
     * <p>⛔ 여기서 PET 만 보고 나머지를 통과시키면 안 된다. 이 API 는 entityId 를 그대로 받아서,
     * 남의 메모 id 만 알면 그 메모의 사진을 보고·올리고·지울 수 있게 된다.
     */
    private void validateEntityAccess(Long userId, EntityType entityType, Long entityId) {
        switch (entityType) {
            case PET -> loadOwnedPet(userId, entityId);
            case MEMO -> loadOwnedPet(userId, memoRepo.findById(entityId)
                    .orElseThrow(() -> new BusinessException(ErrorCode.MEMO_NOT_FOUND)).getPetId());
            case LAYING -> loadOwnedPet(userId, layingRepo.findById(entityId)
                    .orElseThrow(() -> new BusinessException(ErrorCode.LAYING_NOT_FOUND)).getPetId());
            case MATING -> {
                MatingDtl mating = matingRepo.findById(entityId)
                        .orElseThrow(() -> new BusinessException(ErrorCode.MATING_NOT_FOUND));
                boolean kept = (mating.getMalePetId() != null && petKeeper.isKeeper(userId, mating.getMalePetId()))
                        || (mating.getFemalePetId() != null && petKeeper.isKeeper(userId, mating.getFemalePetId()));
                if (!kept) throw new BusinessException(ErrorCode.RECORD_ACCESS_DENIED);
            }
        }
    }

    private PetMst loadOwnedPet(Long userId, Long petId) {
        // 공유 개체 포함 — 사육자(OWNER/KEEPER)면 사진 등록·조회 가능
        return petKeeper.assertKeeper(userId, petId);
    }

    private static String keyPrefix(EntityType entityType, Long entityId) {
        String prefix = switch (entityType) {
            case PET    -> "pets/";
            case MEMO   -> "memos/";
            case MATING -> "matings/";
            case LAYING -> "layings/";
        };
        return prefix + entityId + "/";
    }
}
