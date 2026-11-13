package io.bitpet.inquiry.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.inquiry.dto.InquiryCreateRequest;
import io.bitpet.inquiry.service.InquiryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * 개발자에게 문의하기. 보내기만 있다 — 답장 없는 일방향 건의함이라 조회 API 가 없다.
 */
@Tag(name = "Inquiry", description = "개발자에게 문의하기")
@RestController
@RequestMapping("/api/v1/inquiries")
@RequiredArgsConstructor
public class InquiryController {

    private final InquiryService inquiryService;

    @Operation(summary = "문의 보내기 (24시간 10건)")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Void> create(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody InquiryCreateRequest request) {
        inquiryService.create(principal.userId(), request);
        return ApiResponse.ok();
    }
}
