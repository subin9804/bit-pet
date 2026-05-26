package io.bitpet.photo.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.photo.domain.EntityType;
import io.bitpet.photo.dto.PhotoPresignRequest;
import io.bitpet.photo.dto.PhotoRegisterRequest;
import io.bitpet.photo.dto.PhotoResponse;
import io.bitpet.photo.dto.PresignedUploadResponse;
import io.bitpet.photo.service.PhotoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 폴리모픽 사진 API — /api/v1/photos/**
 * V20 마이그레이션 이후 통합 사진 컨트롤러 (PET / MEMO / MATING / LAYING)
 */
@Tag(name = "Photo", description = "폴리모픽 사진 CRUD (PET/MEMO/MATING/LAYING)")
@RestController
@RequiredArgsConstructor
public class PhotoController {

    private final PhotoService photoService;

    @Operation(summary = "S3 Presigned PUT URL 발급")
    @PostMapping("/api/v1/photos/presign")
    public ApiResponse<PresignedUploadResponse> presign(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody PhotoPresignRequest request) {
        return ApiResponse.ok(photoService.presignUpload(principal.userId(), request));
    }

    @Operation(summary = "S3 업로드 완료 후 DB 등록")
    @PostMapping("/api/v1/photos")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<PhotoResponse> register(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody PhotoRegisterRequest request) {
        return ApiResponse.ok(photoService.registerPhoto(principal.userId(), request));
    }

    @Operation(summary = "사진 목록 조회 (entityType, entityId 필터)")
    @GetMapping("/api/v1/photos")
    public ApiResponse<List<PhotoResponse>> list(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam EntityType entityType,
            @RequestParam Long entityId) {
        return ApiResponse.ok(photoService.listPhotos(principal.userId(), entityType, entityId));
    }

    @Operation(summary = "사진 삭제")
    @DeleteMapping("/api/v1/photos/{photoId}")
    public ApiResponse<Void> delete(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long photoId) {
        photoService.deletePhoto(principal.userId(), photoId);
        return ApiResponse.ok();
    }

    @Operation(summary = "개체 프로필 사진 설정 (PET 한정)")
    @PatchMapping("/api/v1/pets/{petId}/photos/{photoId}/profile")
    public ApiResponse<PhotoResponse> setProfile(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @PathVariable Long photoId) {
        return ApiResponse.ok(photoService.setProfilePhoto(principal.userId(), petId, photoId));
    }
}
