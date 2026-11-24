package io.bitpet.community.service;

import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.community.domain.SuspensionDuration;
import io.bitpet.community.domain.UserSuspensionDtl;
import io.bitpet.community.dto.SuspensionResponse;
import io.bitpet.community.repository.UserSuspensionDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * 커뮤니티 이용 정지 (V5, 2026-11-24).
 *
 * <p><b>커뮤니티 쓰기만 막는다</b> — 글·댓글(작성·수정)·좋아요·사진·신고. 읽기와 자기 글 삭제,
 * 내 개체 기록·루틴은 그대로다. 사육 기록은 개인 데이터라 커뮤니티 위반으로 빼앗지 않는다 (사용자 결정).
 * 로그인을 막지 않으므로 앱은 따로 정지 화면 없이, 쓰려는 순간 서버 메시지를 보여 주면 된다.
 *
 * <p>⛔ 신고 수로 자동 정지하지 말 것 — 자동 블라인드를 안 하는 것과 같은 이유(조리돌림 도구가 된다).
 * 정지는 운영자가 신고를 처리할 때만 생긴다.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SuspensionService {

    private static final ZoneId KST = ZoneId.of("Asia/Seoul");
    private static final DateTimeFormatter UNTIL = DateTimeFormatter.ofPattern("M월 d일 HH:mm").withZone(KST);

    private final UserSuspensionDtlRepository suspensionRepository;
    private final UserMstRepository userRepository;

    /** 커뮤니티에 흔적을 남기는 모든 경로의 맨 앞. 메시지에 언제까지인지 담는다. */
    public void assertNotSuspended(Long userId) {
        if (userId == null) return;
        List<UserSuspensionDtl> active = suspensionRepository.findActive(userId, Instant.now());
        if (active.isEmpty()) return;
        UserSuspensionDtl s = active.get(0);
        String message = s.isPermanent()
                ? "운영정책 위반으로 커뮤니티 이용이 정지됐어요."
                : "운영정책 위반으로 " + UNTIL.format(s.getEndsAt()) + "까지 커뮤니티 이용이 정지됐어요.";
        throw new BusinessException(ErrorCode.COMMUNITY_SUSPENDED, message);
    }

    /** 신고 처리에서 부른다. 이미 정지 중이어도 새 행을 남긴다 — 더 긴 쪽이 이긴다. */
    @Transactional
    public UserSuspensionDtl suspend(Long userId, SuspensionDuration duration, Long reportId,
                                     String reason, Long adminUserId) {
        if (duration == null) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "정지 기간을 골라 주세요.");
        }
        return suspensionRepository.save(UserSuspensionDtl.builder()
                .userId(userId)
                .reportId(reportId)
                .reason(reason)
                .endsAt(duration.endsAtFrom(Instant.now()))
                .createdBy(adminUserId)
                .build());
    }

    public List<SuspensionResponse> listActive() {
        return suspensionRepository.findAllActive(Instant.now()).stream()
                .map(s -> SuspensionResponse.of(s, userRepository.findById(s.getUserId())
                        .map(UserMst::getName).orElse("알 수 없음")))
                .toList();
    }

    @Transactional
    public void release(Long suspensionId, Long adminUserId) {
        UserSuspensionDtl s = suspensionRepository.findById(suspensionId)
                .orElseThrow(() -> new BusinessException(ErrorCode.SUSPENSION_NOT_FOUND));
        s.release(adminUserId);
    }
}
