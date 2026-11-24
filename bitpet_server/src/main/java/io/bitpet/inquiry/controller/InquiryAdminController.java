package io.bitpet.inquiry.controller;

import io.bitpet.auth.domain.AdminRole;
import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.auth.service.AdminGuard;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.inquiry.domain.InquiryCategory;
import io.bitpet.inquiry.dto.InquiryAdminResponse;
import io.bitpet.inquiry.service.InquiryAdminService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** 문의함 (읽기 전용). 🚨 URL 로 보호되지 않는다 — 메서드마다 가드. 이메일이 담기므로 운영자 등급만 */
@Tag(name = "Admin - Inquiry", description = "개발자에게 문의하기 — 읽기 전용")
@RestController
@RequestMapping("/api/v1/admin/inquiries")
@RequiredArgsConstructor
public class InquiryAdminController {

    private final InquiryAdminService inquiryAdminService;
    private final AdminGuard adminGuard;

    @Operation(summary = "문의 목록", description = "최근 것부터. category 를 주면 그 분류만")
    @GetMapping
    public ApiResponse<Page<InquiryAdminResponse>> list(@AuthenticationPrincipal AuthPrincipal principal,
                                                        @RequestParam(required = false) InquiryCategory category,
                                                        @PageableDefault(size = 20) Pageable pageable) {
        adminGuard.assertAnyRole(principal.userId(), AdminRole.SUPER_ADMIN, AdminRole.MODERATOR);
        return ApiResponse.ok(inquiryAdminService.list(category, pageable));
    }
}
