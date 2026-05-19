package io.bitpet.photo.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.photo.dto.PetPhotoResponse;
import io.bitpet.photo.dto.PhotoUploadCompleteRequest;
import io.bitpet.photo.dto.PresignedUploadResponse;
import io.bitpet.photo.service.PetPhotoService;
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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/pets/{petId}/photos")
public class PetPhotoController {

    private final PetPhotoService petPhotoService;

    /** Step 1: presigned PUT URL 요청 */
    @PostMapping("/presign")
    public ApiResponse<PresignedUploadResponse> presign(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @RequestParam String filename) {
        return ApiResponse.ok(petPhotoService.generatePresignedUrl(principal.userId(), petId, filename));
    }

    /** Step 2: 클라이언트가 S3에 직접 PUT 업로드 후, DB 등록 */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<PetPhotoResponse> registerPhoto(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody PhotoUploadCompleteRequest req) {
        return ApiResponse.ok(petPhotoService.registerPhoto(principal.userId(), petId, req));
    }

    @GetMapping
    public ApiResponse<List<PetPhotoResponse>> listPhotos(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(petPhotoService.listPhotos(principal.userId(), petId));
    }

    @DeleteMapping("/{photoId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deletePhoto(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @PathVariable Long photoId) {
        petPhotoService.deletePhoto(principal.userId(), petId, photoId);
    }

    @PatchMapping("/{photoId}/profile")
    public ApiResponse<PetPhotoResponse> setProfilePhoto(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @PathVariable Long photoId) {
        return ApiResponse.ok(petPhotoService.setProfilePhoto(principal.userId(), petId, photoId));
    }
}
