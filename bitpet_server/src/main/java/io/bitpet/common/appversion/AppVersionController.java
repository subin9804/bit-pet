package io.bitpet.common.appversion;

import io.bitpet.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** 앱이 켜질 때 묻는 최소/최신 버전. 로그인 전에도 불리므로 public-paths 에 열려 있다. */
@Tag(name = "App")
@RestController
@RequestMapping("/api/v1/app")
@RequiredArgsConstructor
public class AppVersionController {

    private final AppVersionProperties properties;

    @Operation(summary = "앱 최소·최신 버전 (강제 업데이트 판정용)")
    @GetMapping("/version")
    public ApiResponse<AppVersionProperties.Platform> version(
            @RequestParam(defaultValue = "android") String platform) {
        return ApiResponse.ok("ios".equalsIgnoreCase(platform) ? properties.ios() : properties.android());
    }
}
