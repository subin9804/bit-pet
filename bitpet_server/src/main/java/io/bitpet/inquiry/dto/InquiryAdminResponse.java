package io.bitpet.inquiry.dto;

import io.bitpet.inquiry.domain.InquiryCategory;
import io.bitpet.inquiry.domain.InquiryDtl;

import java.time.Instant;

/** 관리 페이지 문의함 한 줄. 답장 기능은 없다 — 이메일은 운영자가 따로 연락할 때 쓴다. 탈퇴했으면 닉네임·이메일이 null. */
public record InquiryAdminResponse(
        Long id,
        Long userId,
        String nickname,
        String email,
        InquiryCategory category,
        String content,
        String appVersion,
        String platform,
        String osVersion,
        Instant createdAt
) {
    public static InquiryAdminResponse of(InquiryDtl i, String nickname, String email) {
        return new InquiryAdminResponse(i.getId(), i.getUserId(), nickname, email, i.getCategory(),
                i.getContent(), i.getAppVersion(), i.getPlatform(), i.getOsVersion(), i.getCreatedAt());
    }
}
