package io.bitpet.banner.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.banner.dto.HomeBannerResponse;
import io.bitpet.banner.service.HomeBannerService;
import io.bitpet.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Home Banner", description = "홈 상단 배너")
@RestController
@RequestMapping("/api/v1/home/banners")
@RequiredArgsConstructor
public class HomeBannerController {

    private final HomeBannerService bannerService;

    @Operation(summary = "지금 노출 중인 배너",
            description = "켜져 있고 기간 안인 배너를 순서대로. 자녀 계정에는 외부 링크(URL) 배너가 빠진다. 비어 있으면 앱은 배너 자리를 숨긴다.")
    @GetMapping
    public ApiResponse<List<HomeBannerResponse>> list(@AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(bannerService.listLive(principal.userId()));
    }
}
