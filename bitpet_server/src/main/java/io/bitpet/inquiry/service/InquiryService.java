package io.bitpet.inquiry.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.inquiry.domain.InquiryDtl;
import io.bitpet.inquiry.dto.InquiryCreateRequest;
import io.bitpet.inquiry.repository.InquiryDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Service
@RequiredArgsConstructor
public class InquiryService {

    /** 24시간 안에 보낼 수 있는 건수. 버튼 연타·스크립트로 테이블이 쓰레기로 차는 것만 막는다. */
    public static final int DAILY_LIMIT = 10;

    private final InquiryDtlRepository inquiryRepository;

    @Transactional
    public void create(Long userId, InquiryCreateRequest request) {
        Instant since = Instant.now().minus(1, ChronoUnit.DAYS);
        if (inquiryRepository.countByUserIdAndCreatedAtGreaterThanEqual(userId, since) >= DAILY_LIMIT) {
            throw new BusinessException(ErrorCode.INQUIRY_TOO_MANY);
        }
        inquiryRepository.save(InquiryDtl.builder()
                .userId(userId)
                .category(request.category())
                .content(request.content().trim())
                .appVersion(request.appVersion())
                .platform(request.platform())
                .osVersion(request.osVersion())
                .build());
    }
}
