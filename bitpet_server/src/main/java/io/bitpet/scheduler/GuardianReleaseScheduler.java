package io.bitpet.scheduler;

import io.bitpet.auth.service.GuardianService;
import io.bitpet.auth.service.GuardianService.ReleasedChild;
import io.bitpet.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;

/**
 * 만 14세가 된 자녀 계정의 보호자 연결 해제 + 보호자 알림 (V23, 2026-11-06).
 *
 * <p>권한 판정 자체는 배치를 기다리지 않는다 — {@code UserMst.isUnderGuardian()} 가 나이를 매번 계산해서
 * 생일 당일부터 보호자 권한이 사라진다. 이 배치는 해제 시각을 찍고 <b>보호자에게 한 번 알리는</b> 일을 한다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class GuardianReleaseScheduler {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    private final GuardianService guardianService;
    private final NotificationService notificationService;

    /** 매일 Seoul 09:00 — 알림이 가는 일이라 새벽을 피한다 */
    @Scheduled(cron = "0 0 9 * * *", zone = "Asia/Seoul")
    public void releaseChildrenTurned14() {
        run(LocalDate.now(SEOUL));
    }

    void run(LocalDate today) {
        List<ReleasedChild> released = guardianService.releaseChildrenTurned14(today);
        for (ReleasedChild child : released) {
            try {
                notificationService.createSystemNotification(
                        child.guardianUserId(),
                        "자녀 계정이 일반 계정으로 바뀌었어요",
                        child.nickname() + "님이 만 14세가 되어 보호자 연결이 해제됐어요. "
                                + "이제 자녀 계정 목록에서 빠지고, 본인이 직접 계정을 관리해요.");
            } catch (Exception e) {
                // 해제는 이미 커밋됐다 — 알림 하나 실패로 나머지 보호자 알림까지 멈추면 안 된다
                log.warn("guardian release notification failed: childId={}", child.childId(), e);
            }
        }
        if (!released.isEmpty()) {
            log.info("Guardian release: {} child account(s) released", released.size());
        }
    }
}
