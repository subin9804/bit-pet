package io.bitpet.routine.repository;

import io.bitpet.routine.domain.RoutineLogDtl;
import io.bitpet.routine.domain.RoutineLogStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface RoutineLogDtlRepository extends JpaRepository<RoutineLogDtl, Long> {

    @Query("SELECT r FROM RoutineLogDtl r WHERE r.routineId = :routineId AND r.deletedAt IS NULL ORDER BY r.executedAt DESC")
    List<RoutineLogDtl> findAllByRoutineId(@Param("routineId") Long routineId);

    @Query("SELECT r FROM RoutineLogDtl r WHERE r.petId = :petId AND r.deletedAt IS NULL ORDER BY r.executedAt DESC")
    List<RoutineLogDtl> findAllByPetId(@Param("petId") Long petId);

    @Query("""
            SELECT r FROM RoutineLogDtl r
            WHERE r.routineId = :routineId
              AND r.petId = :petId
              AND r.executedAt >= :from
              AND r.executedAt < :to
              AND r.deletedAt IS NULL
            ORDER BY r.executedAt DESC
            """)
    List<RoutineLogDtl> findTodayLogs(@Param("routineId") Long routineId,
                                       @Param("petId") Long petId,
                                       @Param("from") Instant from,
                                       @Param("to") Instant to);

    long countByRoutineIdAndStatusAndDeletedAtIsNull(Long routineId, RoutineLogStatus status);
}
