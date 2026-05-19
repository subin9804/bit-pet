package io.bitpet.routine.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.routine.domain.AlarmMst;
import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.dto.AlarmCreateRequest;
import io.bitpet.routine.dto.AlarmResponse;
import io.bitpet.routine.dto.AlarmUpdateRequest;
import io.bitpet.routine.dto.RoutineCreateRequest;
import io.bitpet.routine.dto.RoutineResponse;
import io.bitpet.routine.dto.RoutineUpdateRequest;
import io.bitpet.routine.repository.AlarmMstRepository;
import io.bitpet.routine.repository.RoutineMstRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RoutineService {

    private final PetMstRepository petRepository;
    private final RoutineMstRepository routineRepository;
    private final AlarmMstRepository alarmRepository;

    // -------------------------------------------------------------------------
    // Routine CRUD
    // -------------------------------------------------------------------------

    public List<RoutineResponse> listRoutines(Long userId, Long petId) {
        verifyPetOwnership(userId, petId);
        return routineRepository.findAllByPetIdOrderByCreatedAtDesc(petId)
                .stream().map(RoutineResponse::from).toList();
    }

    public RoutineResponse getRoutine(Long userId, Long petId, Long routineId) {
        verifyPetOwnership(userId, petId);
        RoutineMst routine = findRoutineOfPet(routineId, petId);
        return RoutineResponse.from(routine);
    }

    @Transactional
    public RoutineResponse createRoutine(Long userId, Long petId, RoutineCreateRequest req) {
        verifyPetOwnership(userId, petId);
        Instant nextDueAt = req.startAt() != null
                ? req.startAt()
                : Instant.now().plus(req.cycleDays(), ChronoUnit.DAYS);

        RoutineMst saved = routineRepository.save(RoutineMst.builder()
                .petId(petId)
                .routineType(req.routineType())
                .title(req.title())
                .cycleDays(req.cycleDays())
                .nextDueAt(nextDueAt)
                .memo(req.memo())
                .build());
        return RoutineResponse.from(saved);
    }

    @Transactional
    public RoutineResponse updateRoutine(Long userId, Long petId, Long routineId,
                                         RoutineUpdateRequest req) {
        verifyPetOwnership(userId, petId);
        RoutineMst routine = findRoutineOfPet(routineId, petId);
        routine.update(req.routineType(), req.title(), req.cycleDays(), req.active(), req.memo());
        return RoutineResponse.from(routine);
    }

    @Transactional
    public void deleteRoutine(Long userId, Long petId, Long routineId) {
        verifyPetOwnership(userId, petId);
        RoutineMst routine = findRoutineOfPet(routineId, petId);
        routineRepository.delete(routine);
    }

    @Transactional
    public RoutineResponse executeRoutine(Long userId, Long petId, Long routineId) {
        verifyPetOwnership(userId, petId);
        RoutineMst routine = findRoutineOfPet(routineId, petId);
        routine.markExecuted(Instant.now());
        return RoutineResponse.from(routine);
    }

    // -------------------------------------------------------------------------
    // Alarm CRUD
    // -------------------------------------------------------------------------

    public List<AlarmResponse> listAlarms(Long userId, Long routineId) {
        RoutineMst routine = findRoutine(routineId);
        verifyPetOwnership(userId, routine.getPetId());
        return alarmRepository.findAllByRoutineIdOrderByAlarmTime(routineId)
                .stream().map(AlarmResponse::from).toList();
    }

    @Transactional
    public AlarmResponse addAlarm(Long userId, Long routineId, AlarmCreateRequest req) {
        RoutineMst routine = findRoutine(routineId);
        verifyPetOwnership(userId, routine.getPetId());
        AlarmMst saved = alarmRepository.save(AlarmMst.builder()
                .routineId(routineId)
                .alarmTime(req.alarmTime())
                .enabled(req.enabled())
                .build());
        return AlarmResponse.from(saved);
    }

    @Transactional
    public AlarmResponse updateAlarm(Long userId, Long routineId, Long alarmId,
                                      AlarmUpdateRequest req) {
        RoutineMst routine = findRoutine(routineId);
        verifyPetOwnership(userId, routine.getPetId());
        AlarmMst alarm = findAlarmOfRoutine(alarmId, routineId);
        alarm.update(req.alarmTime(), req.enabled());
        return AlarmResponse.from(alarm);
    }

    @Transactional
    public void deleteAlarm(Long userId, Long routineId, Long alarmId) {
        RoutineMst routine = findRoutine(routineId);
        verifyPetOwnership(userId, routine.getPetId());
        AlarmMst alarm = findAlarmOfRoutine(alarmId, routineId);
        alarmRepository.delete(alarm);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private void verifyPetOwnership(Long userId, Long petId) {
        PetMst pet = petRepository.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.ROUTINE_ACCESS_DENIED);
        }
    }

    private RoutineMst findRoutine(Long routineId) {
        return routineRepository.findById(routineId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ROUTINE_NOT_FOUND));
    }

    private RoutineMst findRoutineOfPet(Long routineId, Long petId) {
        RoutineMst routine = findRoutine(routineId);
        if (!routine.getPetId().equals(petId)) {
            throw new BusinessException(ErrorCode.ROUTINE_ACCESS_DENIED);
        }
        return routine;
    }

    private AlarmMst findAlarmOfRoutine(Long alarmId, Long routineId) {
        AlarmMst alarm = alarmRepository.findById(alarmId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ALARM_NOT_FOUND));
        if (!alarm.getRoutineId().equals(routineId)) {
            throw new BusinessException(ErrorCode.ROUTINE_ACCESS_DENIED);
        }
        return alarm;
    }
}
