package io.bitpet.storage.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * S3 오브젝트 삭제 재시도 큐 (V54).
 *
 * <p>탈퇴·개체 정리는 하나의 DB 트랜잭션이지만 S3 삭제는 그 안에 넣을 수 없다.
 * 외부 호출이 실패했다고 탈퇴를 롤백할 수는 없고, 반대로 삭제에 성공한 뒤 트랜잭션이
 * 롤백되면 DB 는 멀쩡한데 파일만 사라진다. 그래서 트랜잭션 안에서는 키를 적재만 하고,
 * 커밋 뒤 배치({@code S3DeleteQueueScheduler})가 실제 삭제를 맡는다.
 */
@Entity
@Getter
@Table(name = "s3_delete_queue_dtl")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class S3DeleteQueueDtl extends BaseTimeEntity {

    /** 이 횟수를 넘기면 배치가 더 손대지 않는다 — 버킷·권한 문제라면 재시도로 풀리지 않는다 */
    public static final int MAX_ATTEMPTS = 10;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "s3_key", nullable = false, length = 255)
    private String s3Key;

    @Column(name = "attempt_cnt", nullable = false)
    private int attemptCnt = 0;

    @Column(name = "last_error", columnDefinition = "TEXT")
    private String lastError;

    /** NULL = 미처리. 성공분도 행은 남긴다(무엇을 지웠는지 추적 가능해야 한다) */
    @Column(name = "succeeded_at")
    private Instant succeededAt;

    public static S3DeleteQueueDtl of(String s3Key) {
        S3DeleteQueueDtl row = new S3DeleteQueueDtl();
        row.s3Key = s3Key;
        return row;
    }

    public void markSucceeded() {
        this.succeededAt = Instant.now();
        this.attemptCnt++;
        this.lastError = null;
    }

    public void markFailed(String message) {
        this.attemptCnt++;
        this.lastError = message == null ? null
                : message.substring(0, Math.min(message.length(), 1000));
    }
}
