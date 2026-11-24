package io.bitpet.inquiry.service;

import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.inquiry.domain.InquiryCategory;
import io.bitpet.inquiry.domain.InquiryDtl;
import io.bitpet.inquiry.dto.InquiryAdminResponse;
import io.bitpet.inquiry.repository.InquiryDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** 관리 페이지 문의함 — 읽기 전용 (2026-11-24). 답장·상태 관리는 없다 (일방향 건의함, V3). */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class InquiryAdminService {

    private final InquiryDtlRepository inquiryRepository;
    private final UserMstRepository userRepository;

    public Page<InquiryAdminResponse> list(InquiryCategory category, Pageable pageable) {
        Page<InquiryDtl> page = inquiryRepository.findForAdmin(category, pageable);
        Map<Long, UserMst> users = userRepository.findAllById(
                        page.getContent().stream().map(InquiryDtl::getUserId).distinct().toList())
                .stream().collect(Collectors.toMap(UserMst::getId, Function.identity()));
        return page.map(i -> {
            UserMst u = users.get(i.getUserId());
            return InquiryAdminResponse.of(i, u == null ? null : u.getName(), u == null ? null : u.getEmail());
        });
    }
}
