package io.bitpet.storage.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * S3 삭제 큐를 실제로 소진하는 실행부.
 *
 * <p><b>기본 경로는 커밋 직후 즉시 실행이다.</b> 큐 테이블을 둔 이유는 "나중에 몰아서 지우려고"가
 * 아니라, S3 호출을 트랜잭션 <b>밖으로</b> 빼기 위해서다 — 트랜잭션 안에서 지우면 이후 롤백 시
 * 파일만 사라지고, 반대로 S3 장애가 탈퇴를 롤백시킨다. 커밋된 순간 "이 키는 지워도 된다"가
 * 확정되므로 곧바로 지우면 된다.
 *
 * <p>{@link org.springframework.scheduling.annotation.Scheduled} 배치는 <b>정상 경로가 아니라
 * 재시도 그물</b>이다. S3 일시 장애로 실패했거나, 커밋과 삭제 사이에 서버가 죽어 이벤트가
 * 유실된 행만 주워 담는다. 그래서 주기가 짧을 이유가 없다.
 *
 * <p>{@link #drainAll()}을 별도 빈으로 뺀 이유: 루프가 {@code S3DeleteQueueService.drain()}을
 * 프록시 경유로 호출해야 매 배치가 <b>독립 트랜잭션</b>이 된다. 한 트랜잭션으로 묶으면 수백 건이
 * 커밋 없이 쌓이고, 중간에 터지면 성공 기록까지 통째로 날아가 같은 키를 또 지우게 된다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class S3DeleteQueueDrainer {

    /**
     * 한 번의 소진에서 돌 최대 배치 수(= 최대 {@code 20 × DRAIN_BATCH_SIZE} 건).
     * 계속 실패하는 키가 남아 있어도 여기서 손을 떼고 다음 주기에 맡긴다.
     */
    private static final int MAX_ROUNDS = 20;

    private final S3DeleteQueueService queueService;

    /**
     * 커밋 직후 비동기 소진. 요청 스레드에서 돌리면 탈퇴 응답이 S3 호출 수만큼 늦어진다.
     *
     * <p>실패해도 이미 커밋된 탈퇴에는 영향이 없다 — 남은 키는 재시도 배치가 가져간다.
     */
    @Async
    @TransactionalEventListener
    public void onQueued(S3DeleteQueuedEvent event) {
        log.debug("S3 delete queued: {} key(s), draining after commit", event.queued());
        drainAll();
    }

    /** 더 집어들 게 없을 때까지 배치 반복 */
    public void drainAll() {
        try {
            for (int round = 0; round < MAX_ROUNDS; round++) {
                if (queueService.drain() == 0) return;
            }
            log.warn("S3 delete queue still not empty after {} rounds — 다음 주기로 넘긴다", MAX_ROUNDS);
        } catch (Exception e) {
            // 큐에 남으므로 유실은 아니다. 재시도 배치가 다시 집어간다
            log.error("S3 delete queue drain aborted: {}", e.getMessage(), e);
        }
    }
}
