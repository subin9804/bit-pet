package io.bitpet.routine.repository;

import io.bitpet.routine.domain.AlarmMst;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AlarmMstRepository extends JpaRepository<AlarmMst, Long> {

    List<AlarmMst> findAllByRoutineIdOrderByAlarmTime(Long routineId);
}
