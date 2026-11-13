package io.bitpet.inquiry;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.inquiry.domain.InquiryCategory;
import io.bitpet.inquiry.domain.InquiryDtl;
import io.bitpet.inquiry.dto.InquiryCreateRequest;
import io.bitpet.inquiry.repository.InquiryDtlRepository;
import io.bitpet.inquiry.service.InquiryService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 개발자에게 문의하기 (V3, 2026-11-14) — 저장 · 24시간 10건 제한 · 탈퇴 시 삭제.
 */
class InquiryIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private InquiryService inquiryService;
    @Autowired private InquiryDtlRepository inquiryRepository;

    @Test
    void saves_trimmed_content_with_device_info() {
        Long user = signup();

        inquiryService.create(user, new InquiryCreateRequest(
                InquiryCategory.BUG, "  사진이 안 올라가요  ", "1.0.0+3", "android", "Android 14"));

        List<InquiryDtl> saved = inquiryRepository.findAll().stream()
                .filter(i -> i.getUserId().equals(user)).toList();
        assertThat(saved).hasSize(1);
        assertThat(saved.get(0).getContent()).isEqualTo("사진이 안 올라가요");
        assertThat(saved.get(0).getCategory()).isEqualTo(InquiryCategory.BUG);
        assertThat(saved.get(0).getAppVersion()).isEqualTo("1.0.0+3");
    }

    @Test
    void blocks_after_daily_limit() {
        Long user = signup();
        for (int i = 0; i < InquiryService.DAILY_LIMIT; i++) {
            inquiryService.create(user, request("제안 " + i));
        }

        assertThatThrownBy(() -> inquiryService.create(user, request("한 번 더")))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.INQUIRY_TOO_MANY);
        assertThat(inquiryRepository.countByUserId(user)).isEqualTo(InquiryService.DAILY_LIMIT);
    }

    @Test
    void withdraw_deletes_inquiries() {
        Long user = signup();
        Long other = signup();
        inquiryService.create(user, request("내 문의"));
        inquiryService.create(other, request("남의 문의"));

        authService.withdraw(user, false);

        assertThat(inquiryRepository.countByUserId(user)).isZero();
        assertThat(inquiryRepository.countByUserId(other)).isEqualTo(1);
    }

    private InquiryCreateRequest request(String content) {
        return new InquiryCreateRequest(InquiryCategory.SUGGESTION, content, null, null, null);
    }

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "inq" + n + "@example.com", "Passw0rd!23", "inquser" + n, null,
                true, true, true, null, false, null)).id();
    }
}
