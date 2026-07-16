package io.bitpet.routine.repository;

import io.bitpet.routine.domain.RoutineMst;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public interface RoutineMstRepository extends JpaRepository<RoutineMst, Long> {

    // ── 개인 루틴 조회 (루틴은 생성자 소유) ──────────────────────────────────────
    List<RoutineMst> findAllByUserIdOrderByCreatedAtDesc(Long userId);

    List<RoutineMst> findAllByUserIdAndActiveOrderByCreatedAtDesc(Long userId, boolean active);

    /**
     * 오늘 날짜(Seoul)가 due이고, 알람 시각이 지났으며, 오늘 아직 알림을 보내지 않은 루틴.
     * nextDueAt, lastNotifiedAt(날짜 부분)을 Seoul 오늘 기준으로 비교.
     */
    @Query("""
            SELECT r FROM RoutineMst r
            WHERE r.active = true
              AND r.alarmEnabled = true
              AND r.nextDueAt IS NOT NULL
              AND r.nextDueAt = :today
              AND r.alarmTime <= :currentSeoulTime
              AND (r.lastNotifiedAt IS NULL OR r.lastNotifiedAt < :startOfToday)
            """)
    List<RoutineMst> findReadyToNotify(
            @Param("today") LocalDate today,
            @Param("currentSeoulTime") LocalTime currentSeoulTime,
            @Param("startOfToday") Instant startOfToday
    );

    /** 예정일이 오늘보다 이전인 미완료 루틴 (자정 배치에서 다음 주기로 전진) */
    @Query("""
            SELECT r FROM RoutineMst r
            WHERE r.active = true
              AND r.nextDueAt IS NOT NULL
              AND r.nextDueAt < :today
            """)
    List<RoutineMst> findOverduePastDate(@Param("today") LocalDate today);
}
