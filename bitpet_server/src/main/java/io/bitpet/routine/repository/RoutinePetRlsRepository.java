package io.bitpet.routine.repository;

import io.bitpet.routine.domain.RoutinePetRls;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface RoutinePetRlsRepository extends JpaRepository<RoutinePetRls, Long> {

    List<RoutinePetRls> findAllByRoutineIdOrderByPetIdAsc(Long routineId);

    List<RoutinePetRls> findAllByPetId(Long petId);

    Optional<RoutinePetRls> findByRoutineIdAndPetId(Long routineId, Long petId);

    boolean existsByRoutineIdAndPetId(Long routineId, Long petId);

    void deleteByRoutineIdAndPetId(Long routineId, Long petId);

    long countByRoutineId(Long routineId);

    @Query("SELECT rp.petId FROM RoutinePetRls rp WHERE rp.routineId = :routineId ORDER BY rp.petId ASC")
    List<Long> findPetIdsByRoutineId(@Param("routineId") Long routineId);
}
