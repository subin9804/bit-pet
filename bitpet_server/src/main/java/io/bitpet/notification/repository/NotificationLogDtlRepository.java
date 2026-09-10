package io.bitpet.notification.repository;

import io.bitpet.notification.domain.NotificationLogDtl;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface NotificationLogDtlRepository extends JpaRepository<NotificationLogDtl, Long> {

    List<NotificationLogDtl> findTop50ByUserIdOrderBySentAtDesc(Long userId);

    /**
     * 보존기간이 지난 알림 로그를 <b>한 묶음씩</b> 삭제한다.
     *
     * <p>네이티브 쿼리인 이유는 {@code LIMIT} 이다. JPQL 의 DELETE 에는 LIMIT 이 없어서
     * 조건에 맞는 행을 한 번에 다 지우게 되는데, 처음 도입하는 시점엔 그게 수백만 행일 수 있다.
     * 하나의 거대한 트랜잭션은 락을 오래 잡고 WAL 을 불려 복제·백업까지 흔든다.
     *
     * <p>서브쿼리로 id 를 먼저 뽑고 그걸로 지우는 형태인 건 PostgreSQL 의 DELETE 가
     * LIMIT 을 직접 못 받기 때문이다.
     *
     * @return 실제로 지운 행 수. 0이면 더 지울 게 없다는 뜻이라 호출자가 반복을 멈춘다
     */
    @Modifying
    @Query(value = """
            DELETE FROM notification_log_dtl
            WHERE id IN (
                SELECT id FROM notification_log_dtl
                WHERE sent_at < :threshold
                ORDER BY sent_at
                LIMIT :batchSize
            )
            """, nativeQuery = true)
    int deleteSentBefore(@Param("threshold") Instant threshold, @Param("batchSize") int batchSize);
}
