package io.bitpet.storage.service;

import io.bitpet.storage.S3Service;
import io.bitpet.storage.domain.S3DeleteQueueDtl;
import io.bitpet.storage.repository.S3DeleteQueueDtlRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.List;

/**
 * S3 오브젝트 삭제를 트랜잭션 밖으로 미루는 큐.
 *
 * <p>적재({@link #enqueue})는 호출부의 트랜잭션에 그대로 참여한다 — 탈퇴가 롤백되면
 * 삭제 예약도 함께 사라져야 한다. 실제 삭제({@link #drain})는 커밋 뒤 배치가 돌린다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class S3DeleteQueueService {

    /** 한 번에 처리할 최대 건수. 탈퇴 한 건이 수백 장을 남길 수 있어 상한을 둔다 */
    private static final int DRAIN_BATCH_SIZE = 200;

    private final S3DeleteQueueDtlRepository queueRepository;
    private final S3Service s3Service;
    private final ApplicationEventPublisher eventPublisher;

    /**
     * 호출부 트랜잭션에 참여 — 롤백되면 예약도 없던 일이 된다.
     *
     * <p>적재와 함께 이벤트를 쏜다. {@link S3DeleteQueueDrainer}가 <b>커밋 직후</b> 받아 바로
     * 지우므로, 배치를 기다릴 필요가 없다.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public void enqueue(Collection<String> s3Keys) {
        if (s3Keys == null || s3Keys.isEmpty()) return;
        List<S3DeleteQueueDtl> rows = s3Keys.stream()
                .filter(k -> k != null && !k.isBlank())
                .distinct()
                .map(S3DeleteQueueDtl::of)
                .toList();
        if (rows.isEmpty()) return;
        queueRepository.saveAll(rows);
        eventPublisher.publishEvent(new S3DeleteQueuedEvent(rows.size()));
    }

    /**
     * 큐를 한 배치 처리한다. 개별 키 삭제 실패는 그 행에만 기록하고 넘어간다 —
     * 한 장 때문에 나머지가 밀리면 큐가 영영 줄지 않는다.
     *
     * <p>S3 DELETE 는 멱등이라 중복 실행돼도 해롭지 않다 (커밋 후 소진과 재시도 배치가
     * 겹칠 수 있다).
     *
     * @return 이번에 <b>집어든</b> 행 수. 0이면 처리할 게 남지 않았다는 뜻이라 반복 종료 신호가 된다
     */
    @Transactional
    public int drain() {
        List<S3DeleteQueueDtl> pending = queueRepository.findPending(
                S3DeleteQueueDtl.MAX_ATTEMPTS, PageRequest.of(0, DRAIN_BATCH_SIZE));
        if (pending.isEmpty()) return 0;

        int succeeded = 0;
        for (S3DeleteQueueDtl row : pending) {
            try {
                s3Service.deleteObject(row.getS3Key());
                row.markSucceeded();
                succeeded++;
            } catch (Exception e) {
                row.markFailed(e.getMessage());
                log.warn("S3 delete failed: key={}, attempt={}, err={}",
                        row.getS3Key(), row.getAttemptCnt(), e.getMessage());
            }
        }
        log.info("S3 delete queue drained: {}/{} succeeded", succeeded, pending.size());
        return pending.size();
    }
}
