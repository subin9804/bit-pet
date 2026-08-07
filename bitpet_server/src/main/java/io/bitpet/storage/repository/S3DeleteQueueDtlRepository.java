package io.bitpet.storage.repository;

import io.bitpet.storage.domain.S3DeleteQueueDtl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface S3DeleteQueueDtlRepository extends JpaRepository<S3DeleteQueueDtl, Long> {

    /** 미처리 + 재시도 한계 이내. 오래된 것부터 */
    @Query("""
            SELECT q FROM S3DeleteQueueDtl q
            WHERE q.succeededAt IS NULL AND q.attemptCnt < :maxAttempts
            ORDER BY q.id ASC
            """)
    List<S3DeleteQueueDtl> findPending(@Param("maxAttempts") int maxAttempts, Pageable pageable);
}
