package io.bitpet.banner.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.auth.service.AdminGuard;
import io.bitpet.banner.dto.BannerImageResponse;
import io.bitpet.banner.dto.HomeBannerAdminResponse;
import io.bitpet.banner.dto.HomeBannerRequest;
import io.bitpet.banner.service.HomeBannerService;
import io.bitpet.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * 배너 관리 — 웹 관리 페이지(/admin/banners)가 부른다.
 *
 * <p>🚨 {@code /api/v1/admin/**} 은 URL 로 보호되지 않는다. 모든 메서드가 {@link AdminGuard} 를 직접 통과시킨다.
 */
@Tag(name = "Admin - Banner", description = "홈 배너 관리")
@RestController
@RequestMapping("/api/v1/admin/banners")
@RequiredArgsConstructor
public class HomeBannerAdminController {

    private final HomeBannerService bannerService;
    private final AdminGuard adminGuard;

    @Operation(summary = "배너 전체 (꺼진 것·기간 밖 포함)")
    @GetMapping
    public ApiResponse<List<HomeBannerAdminResponse>> list(@AuthenticationPrincipal AuthPrincipal principal) {
        adminGuard.assertAdmin(principal.userId());
        return ApiResponse.ok(bannerService.listAll());
    }

    @Operation(summary = "배너 등록")
    @PostMapping
    public ApiResponse<HomeBannerAdminResponse> create(@AuthenticationPrincipal AuthPrincipal principal,
                                                       @Valid @RequestBody HomeBannerRequest request) {
        adminGuard.assertAdmin(principal.userId());
        return ApiResponse.ok(bannerService.create(request));
    }

    @Operation(summary = "배너 수정 (전체 덮어쓰기)")
    @PutMapping("/{id}")
    public ApiResponse<HomeBannerAdminResponse> update(@AuthenticationPrincipal AuthPrincipal principal,
                                                       @PathVariable Long id,
                                                       @Valid @RequestBody HomeBannerRequest request) {
        adminGuard.assertAdmin(principal.userId());
        return ApiResponse.ok(bannerService.update(id, request));
    }

    @Operation(summary = "배너 삭제", description = "이미지도 같이 지운다. 잠깐 내리기만 하려면 active=false 로 수정")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@AuthenticationPrincipal AuthPrincipal principal, @PathVariable Long id) {
        adminGuard.assertAdmin(principal.userId());
        bannerService.delete(id);
        return ApiResponse.ok();
    }

    @Operation(summary = "배너 이미지 업로드", description = "PNG·JPG·WEBP·GIF, 5MB 까지. 돌려받은 imageKey 를 등록·수정 요청에 넣는다")
    @PostMapping(value = "/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<BannerImageResponse> uploadImage(@AuthenticationPrincipal AuthPrincipal principal,
                                                        @RequestParam("file") MultipartFile file) {
        adminGuard.assertAdmin(principal.userId());
        return ApiResponse.ok(bannerService.uploadImage(file));
    }
}
