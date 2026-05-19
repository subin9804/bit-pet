package io.bitpet.routine.repository;

import io.bitpet.routine.domain.RoutineMst;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface RoutineMstRepository extends JpaRepository<RoutineMst, Long> {

    List<RoutineMst> findAllByPetIdOrderByCreatedAtDesc(Long petId);

    @Query("SELECT r FROM RoutineMst r WHERE r.active = true AND r.nextDueAt IS NOT NULL AND r.nextDueAt <= :now")
    List<RoutineMst> findOverdueRoutines(@Param("now") Instant now);
}
