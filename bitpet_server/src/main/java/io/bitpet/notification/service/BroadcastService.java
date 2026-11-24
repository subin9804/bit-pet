package io.bitpet.notification.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.notification.domain.PushBroadcastDtl;
import io.bitpet.notification.dto.BroadcastPreviewResponse;
import io.bitpet.notification.dto.BroadcastRequest;
import io.bitpet.notification.dto.BroadcastResponse;
import io.bitpet.notification.repository.PushBroadcastDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.List;

/**
 * 운영자 전체 푸시 (V5, 2026-11-24). 알림 종류는 SYSTEM — 사용자가 끌 수 없는 종류라
 * <b>광고는 반드시 marketing=true 로</b> 보내야 동의자에게만 간다.
 *
 * <p>marketing=true 는 정보통신망법 제50조를 따른다:
 * 동의자에게만 · 제목 맨 앞 "(광고)" · 본문에 수신거부 방법 · 21시~08시 발송 금지.
 * ⛔ 이 넷 중 하나라도 운영자 선택으로 끌 수 있게 만들지 말 것.
 */
@Service
@RequiredArgsConstructor
public class BroadcastService {

    private static final ZoneId KST = ZoneId.of("Asia/Seoul");
    static final String AD_PREFIX = "(광고) ";
    static final String OPT_OUT = "\n\n수신거부: 앱 > 마이 > 알림 설정에서 마케팅 알림을 끌 수 있어요.";

    private final PushBroadcastDtlRepository broadcastRepository;
    private final BroadcastSender sender;

    public BroadcastPreviewResponse preview() {
        return new BroadcastPreviewResponse(
                broadcastRepository.findAllActiveUserIds().size(),
                broadcastRepository.findMarketingConsentedUserIds().size(),
                isQuietHour(ZonedDateTime.now(KST)));
    }

    public BroadcastResponse send(Long adminUserId, BroadcastRequest req) {
        if (req.marketing() && isQuietHour(ZonedDateTime.now(KST))) {
            throw new BusinessException(ErrorCode.BROADCAST_QUIET_HOURS);
        }
        List<Long> targets = req.marketing()
                ? broadcastRepository.findMarketingConsentedUserIds()
                : broadcastRepository.findAllActiveUserIds();

        PushBroadcastDtl saved = broadcastRepository.save(PushBroadcastDtl.builder()
                .title(req.title().trim())
                .body(req.body().trim())
                .marketing(req.marketing())
                .targetCount(targets.size())
                .createdBy(adminUserId)
                .build());

        String title = req.marketing() ? AD_PREFIX + saved.getTitle() : saved.getTitle();
        String body = req.marketing() ? saved.getBody() + OPT_OUT : saved.getBody();
        // 이력 행이 커밋된 뒤에 보낸다 — 이 메서드는 트랜잭션이 없어 save 가 이미 커밋됐다
        sender.send(saved.getId(), targets, title, body);
        return BroadcastResponse.from(saved);
    }

    public Page<BroadcastResponse> history(Pageable pageable) {
        return broadcastRepository.findAllByOrderByCreatedAtDesc(pageable).map(BroadcastResponse::from);
    }

    /** 21:00 ~ 07:59 (한국시간) — 광고 야간 전송 금지 구간 */
    static boolean isQuietHour(ZonedDateTime kstNow) {
        int h = kstNow.getHour();
        return h >= 21 || h < 8;
    }
}
