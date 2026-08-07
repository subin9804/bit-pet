package io.bitpet.scheduler;

import io.bitpet.pet.service.PetWithdrawalService;
import io.bitpet.storage.service.S3DeleteQueueDrainer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 고아 개체 정리 · S3 삭제 큐 소진 배치.
 *
 * <p>고아 개체는 신규 참조 대상에서 제외되므로(부모 등록·메이팅 상대 지정 불가)
 * 참조 수가 단조 감소한다. 여기서 참조 0이 된 것을 지워 주면 시간이 지나면서 자연 소멸한다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OrphanPetCleanupScheduler {

    /** 한 라운드에 처리할 개체 수 */
    private static final int ROUND_SIZE = 200;

    /** 연쇄 삭제 방어선. 정상 데이터라면 세대 수만큼(한 자릿수)이면 끝난다 */
    private static final int MAX_ROUNDS = 50;

    private final PetWithdrawalService withdrawalService;
    private final S3DeleteQueueDrainer s3DeleteQueue;

    /**
     * 매일 Seoul 03:10. 지운 개체가 부모로 걸고 있던 행도 함께 사라지면서
     * 위 세대가 새로 참조 0이 될 수 있어, 더 지울 게 없을 때까지 반복한다.
     */
    @Scheduled(cron = "0 10 3 * * *", zone = "Asia/Seoul")
    public void cleanupOrphanPets() {
        int total = 0;
        for (int round = 0; round < MAX_ROUNDS; round++) {
            int deleted = withdrawalService.cleanupUnreferencedOrphans(ROUND_SIZE);
            if (deleted == 0) break;
            total += deleted;
        }
        if (total > 0) {
            log.info("Orphan pet cleanup: {} pet(s) purged", total);
        }
    }

    /**
     * S3 삭제 큐 <b>재시도</b>. 정상 경로는 커밋 직후 {@link S3DeleteQueueDrainer}가 이미 끝낸다 —
     * 여기는 S3 일시 장애로 실패했거나 커밋과 삭제 사이에 서버가 죽어 남은 행만 줍는다.
     *
     * <p>그래서 주기가 짧을 이유가 없다. 짧게 잡으면 평소엔 빈 큐를 확인하는 쿼리만 반복된다.
     */
    @Scheduled(fixedDelay = 3_600_000, initialDelay = 120_000)
    public void retryFailedS3Deletes() {
        s3DeleteQueue.drainAll();
    }
}
