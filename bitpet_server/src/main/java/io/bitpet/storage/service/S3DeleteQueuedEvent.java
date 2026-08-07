package io.bitpet.storage.service;

/**
 * S3 삭제 예약이 적재됐다는 신호. 커밋된 뒤에만 의미가 있으므로
 * {@link S3DeleteQueueDrainer}가 AFTER_COMMIT 으로 받는다.
 *
 * @param queued 이번 트랜잭션에서 적재한 키 수 (로그·판단용)
 */
public record S3DeleteQueuedEvent(int queued) {}
