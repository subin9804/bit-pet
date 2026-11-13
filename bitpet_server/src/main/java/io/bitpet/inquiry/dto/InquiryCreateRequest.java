package io.bitpet.inquiry.dto;

import io.bitpet.inquiry.domain.InquiryCategory;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 문의 보내기. 앱 버전·플랫폼·OS 는 앱이 채워 보낸다 (사용자가 적는 칸이 아니다).
 */
public record InquiryCreateRequest(
        @NotNull InquiryCategory category,
        @NotBlank @Size(max = 2000) String content,
        @Size(max = 30) String appVersion,
        @Size(max = 10) String platform,
        @Size(max = 100) String osVersion
) {}
