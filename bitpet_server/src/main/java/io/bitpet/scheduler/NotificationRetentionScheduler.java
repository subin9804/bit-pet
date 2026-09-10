package io.bitpet.scheduler;

import io.bitpet.notification.service.NotificationRetentionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 오래된 알림 로그 삭제 배치.
 *
 * <p>{@code notification_log_dtl} 은 지금까지 지워지는 경로가 하나도 없었다. 루틴 알람은
 * 유저당 하루 몇 건씩 쌓이므로 이 테이블만 단조 증가한다.
 *
 * <p>앱 알림함이 최근 50건만 보여주므로 보존기간이 지난 행은 아무도 볼 수 없다.
 * 그래도 90일이나 두는 건 <b>장애를 조사할 때 필요하기 때문</b>이다 — "알림이 안 왔다"는
 * 문의는 며칠 뒤에 들어오고, 그때 status(SENT/SKIPPED/FAILED)와 error_message 를
 * 봐야 한다. 며칠로 조이면 그 근거가 먼저 사라진다.
 */
@Slf4j
@Component
public class NotificationRetentionScheduler {

    /** 한 트랜잭션에 지울 행 수. 첫 실행에서 수백만 행을 한 번에 지우지 않기 위한 것 */
    private static final int BATCH_SIZE = 5_000;

    /**
     * 방어선. 정상 운영이라면 매일 하루치(배치 한두 개)면 끝난다. 여기에 걸린다는 건
     * 첫 실행이거나 배치가 며칠 멈춰 있었다는 뜻이고, 남은 건 다음 날 이어서 지운다 —
     * 한 번에 끝내겠다고 밤새 도는 것보다 낫다.
     */
    private static final int MAX_ROUNDS = 200;

    private final NotificationRetentionService retentionService;
    private final int retentionDays;

    public NotificationRetentionScheduler(
            NotificationRetentionService retentionService,
            @Value("${bitpet.notification.retention-days:90}") int retentionDays) {
        this.retentionService = retentionService;
        this.retentionDays = retentionDays;
    }

    /**
     * 매일 Seoul 03:30. 03:10 의 고아 개체 정리와 겹치지 않게 뒤로 뒀다 —
     * 둘 다 대량 삭제라 같은 시각에 돌면 디스크 I/O 를 서로 뺏는다.
     */
    @Scheduled(cron = "0 30 3 * * *", zone = "Asia/Seoul")
    public void purgeOldNotifications() {
        // 0 이하면 정리를 끄는 것으로 본다. 운영 중 문제가 생겼을 때 배포 없이
        // 환경변수만으로 멈출 수 있어야 한다 (삭제는 되돌릴 수 없다).
        if (retentionDays <= 0) {
            return;
        }

        int total = 0;
        for (int round = 0; round < MAX_ROUNDS; round++) {
            int deleted = retentionService.purgeBatch(retentionDays, BATCH_SIZE);
            if (deleted == 0) break;
            total += deleted;
        }
        if (total > 0) {
            log.info("Notification log retention: {} row(s) purged (older than {} days)",
                    total, retentionDays);
        }
    }
}
