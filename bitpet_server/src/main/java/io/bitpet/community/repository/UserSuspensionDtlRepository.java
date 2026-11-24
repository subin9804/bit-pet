package io.bitpet.community.repository;

import io.bitpet.community.domain.UserSuspensionDtl;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface UserSuspensionDtlRepository extends JpaRepository<UserSuspensionDtl, Long> {

    /** 지금 걸려 있는 정지. 여러 개면 가장 늦게 끝나는(영구 먼저) 것이 앞이다. */
    @Query("""
            SELECT s FROM UserSuspensionDtl s
            WHERE s.userId = :userId AND s.releasedAt IS NULL
              AND (s.endsAt IS NULL OR s.endsAt > :now)
            ORDER BY CASE WHEN s.endsAt IS NULL THEN 0 ELSE 1 END, s.endsAt DESC
            """)
    List<UserSuspensionDtl> findActive(@Param("userId") Long userId, @Param("now") Instant now);

    /** 관리 페이지용 — 지금 정지 중인 전체 */
    @Query("""
            SELECT s FROM UserSuspensionDtl s
            WHERE s.releasedAt IS NULL AND (s.endsAt IS NULL OR s.endsAt > :now)
            ORDER BY s.createdAt DESC
            """)
    List<UserSuspensionDtl> findAllActive(@Param("now") Instant now);

    long countByUserId(Long userId);
}
