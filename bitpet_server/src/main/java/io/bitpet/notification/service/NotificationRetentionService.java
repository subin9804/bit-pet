package io.bitpet.notification.service;

import io.bitpet.notification.repository.NotificationLogDtlRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

/**
 * 알림 로그 보존기간 정리.
 *
 * <p>앱의 알림함은 {@code findTop50ByUserIdOrderBySentAtDesc} — <b>최근 50건만</b> 보여준다.
 * 그보다 오래된 행은 어떤 화면에서도 조회되지 않으므로, 보관해봐야 테이블만 커진다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationRetentionService {

    private final NotificationLogDtlRepository notificationLogRepository;

    /**
     * 한 배치를 <b>독립 트랜잭션</b>으로 지운다.
     *
     * <p>루프를 이 클래스 밖(스케줄러)에 두고 메서드 하나가 배치 하나만 맡는 건, 프록시를
     * 거쳐야 배치마다 트랜잭션이 새로 열리기 때문이다. 전체를 한 트랜잭션으로 묶으면
     * 도중에 실패했을 때 이미 지운 것까지 되살아나 다음 날 같은 일을 처음부터 다시 한다.
     * ({@code S3DeleteQueueDrainer} 가 같은 이유로 같은 모양이다.)
     *
     * @return 지운 행 수
     */
    @Transactional
    public int purgeBatch(int retentionDays, int batchSize) {
        Instant threshold = Instant.now().minus(retentionDays, ChronoUnit.DAYS);
        return notificationLogRepository.deleteSentBefore(threshold, batchSize);
    }
}
