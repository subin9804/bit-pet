package io.bitpet.routine.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.record.domain.FeedingDtl;
import io.bitpet.record.domain.WeightDtl;
import io.bitpet.record.domain.WeightSource;
import io.bitpet.record.repository.FeedingDtlRepository;
import io.bitpet.record.repository.WeightDtlRepository;
import io.bitpet.routine.domain.RoutineLogDtl;
import io.bitpet.routine.domain.RoutineLogStatus;
import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.domain.RoutinePetRls;
import io.bitpet.routine.domain.RoutineType;
import io.bitpet.routine.dto.RoutineCompleteBatchRequest;
import io.bitpet.routine.dto.RoutineCompleteIndividualRequest;
import io.bitpet.routine.dto.RoutineCreateRequest;
import io.bitpet.routine.dto.RoutineLogResponse;
import io.bitpet.routine.dto.RoutineResponse;
import io.bitpet.routine.dto.TodayRoutineResponse;
import io.bitpet.routine.dto.RoutineUpdateRequest;
import io.bitpet.routine.repository.RoutineLogDtlRepository;
import io.bitpet.routine.repository.RoutineMstRepository;
import io.bitpet.routine.repository.RoutinePetRlsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RoutineService {

    private final RoutineMstRepository routineRepository;
    private final RoutinePetRlsRepository routinePetRepository;
    private final RoutineLogDtlRepository routineLogRepository;
    private final PetMstRepository petRepository;
    private final FeedingDtlRepository feedingRepository;
    private final WeightDtlRepository weightRepository;

    // -------------------------------------------------------------------------
    // Routine CRUD (user-owned)
    // -------------------------------------------------------------------------

    public List<RoutineResponse> listRoutines(Long userId) {
        List<RoutineMst> routines = routineRepository.findAllByUserIdOrderByCreatedAtDesc(userId);
        return routines.stream().map(r -> {
            List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(r.getId());
            return RoutineResponse.from(r, petIds);
        }).toList();
    }

    public RoutineResponse getRoutine(Long userId, Long routineId) {
        RoutineMst routine = findOwnedRoutine(userId, routineId);
        List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(routineId);
        return RoutineResponse.from(routine, petIds);
    }

    @Transactional
    public RoutineResponse createRoutine(Long userId, RoutineCreateRequest req) {
        Instant nextDueAt = req.startAt() != null
                ? req.startAt()
                : Instant.now().plus(req.cycleDays(), ChronoUnit.DAYS);

        RoutineMst saved = routineRepository.save(RoutineMst.builder()
                .userId(userId)
                .routineType(req.routineType())
                .title(req.title())
                .cycleDays(req.cycleDays())
                .alarmTime(req.alarmTime())
                .alarmEnabled(req.alarmEnabled())
                .nextDueAt(nextDueAt)
                .memo(req.memo())
                .build());

        List<Long> petIds = new ArrayList<>();
        if (req.petIds() != null) {
            for (Long petId : req.petIds()) {
                verifyPetOwnership(userId, petId);
                routinePetRepository.save(RoutinePetRls.builder()
                        .routineId(saved.getId())
                        .petId(petId)
                        .build());
                petIds.add(petId);
            }
        }
        return RoutineResponse.from(saved, petIds);
    }

    @Transactional
    public RoutineResponse updateRoutine(Long userId, Long routineId, RoutineUpdateRequest req) {
        RoutineMst routine = findOwnedRoutine(userId, routineId);
        routine.update(req.routineType(), req.title(), req.cycleDays(),
                req.alarmTime(), req.alarmEnabled(), req.active(), req.memo());
        List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(routineId);
        return RoutineResponse.from(routine, petIds);
    }

    @Transactional
    public void deleteRoutine(Long userId, Long routineId) {
        RoutineMst routine = findOwnedRoutine(userId, routineId);
        routineRepository.delete(routine);
    }

    // -------------------------------------------------------------------------
    // Pet subscription (routine_pet_rls)
    // -------------------------------------------------------------------------

    @Transactional
    public void subscribePet(Long userId, Long routineId, Long petId) {
        findOwnedRoutine(userId, routineId);
        verifyPetOwnership(userId, petId);
        if (!routinePetRepository.existsByRoutineIdAndPetId(routineId, petId)) {
            routinePetRepository.save(RoutinePetRls.builder()
                    .routineId(routineId)
                    .petId(petId)
                    .build());
        }
    }

    @Transactional
    public void unsubscribePet(Long userId, Long routineId, Long petId) {
        findOwnedRoutine(userId, routineId);
        routinePetRepository.deleteByRoutineIdAndPetId(routineId, petId);
    }

    public List<Long> listSubscribedPets(Long userId, Long routineId) {
        findOwnedRoutine(userId, routineId);
        return routinePetRepository.findPetIdsByRoutineId(routineId);
    }

    // -------------------------------------------------------------------------
    // Today's routines — completion status per pet
    // -------------------------------------------------------------------------

    public List<TodayRoutineResponse> listTodayRoutines(Long userId) {
        Instant[] todayRange = todayRange();
        List<RoutineMst> routines = routineRepository.findAllByUserIdAndActiveOrderByCreatedAtDesc(userId, true);
        return routines.stream().map(r -> {
            List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(r.getId());
            return TodayRoutineResponse.from(r, buildPetTodayStatuses(r.getId(), petIds, todayRange[0], todayRange[1]));
        }).toList();
    }

    public TodayRoutineResponse getTodayRoutineStatus(Long userId, Long routineId) {
        RoutineMst routine = findOwnedRoutine(userId, routineId);
        Instant[] todayRange = todayRange();
        List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(routineId);
        return TodayRoutineResponse.from(routine, buildPetTodayStatuses(routineId, petIds, todayRange[0], todayRange[1]));
    }

    private List<TodayRoutineResponse.PetTodayStatus> buildPetTodayStatuses(Long routineId, List<Long> petIds,
                                                                              Instant from, Instant to) {
        if (petIds.isEmpty()) return List.of();
        List<RoutineLogDtl> todayLogs = routineLogRepository.findTodayCompletedLogs(routineId, petIds, from, to);
        Map<Long, RoutineLogDtl> logByPetId = todayLogs.stream()
                .collect(Collectors.toMap(RoutineLogDtl::getPetId, l -> l, (a, b) -> a));
        return petIds.stream().map(petId -> {
            PetMst pet = petRepository.findById(petId).orElse(null);
            String petName = pet != null ? pet.getName() : "";
            RoutineLogDtl log = logByPetId.get(petId);
            return new TodayRoutineResponse.PetTodayStatus(
                    petId, petName, log != null,
                    log != null ? log.getId() : null,
                    log != null ? log.getExecutedAt() : null
            );
        }).toList();
    }

    private static Instant[] todayRange() {
        Instant from = LocalDate.now(ZoneOffset.UTC).atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant to = from.plus(1, ChronoUnit.DAYS);
        return new Instant[]{from, to};
    }

    // -------------------------------------------------------------------------
    // Pet view: routines with subscription status
    // -------------------------------------------------------------------------

    public List<RoutineWithSubscriptionResponse> listRoutinesForPet(Long userId, Long petId) {
        verifyPetOwnership(userId, petId);
        List<RoutineMst> routines = routineRepository.findAllByUserIdAndActiveOrderByCreatedAtDesc(userId, true);
        return routines.stream().map(r -> {
            boolean subscribed = routinePetRepository.existsByRoutineIdAndPetId(r.getId(), petId);
            List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(r.getId());
            return new RoutineWithSubscriptionResponse(RoutineResponse.from(r, petIds), subscribed);
        }).toList();
    }

    public record RoutineWithSubscriptionResponse(RoutineResponse routine, boolean subscribed) {}

    // -------------------------------------------------------------------------
    // Routine completion — batch (all pets, same data)
    // -------------------------------------------------------------------------

    @Transactional
    public List<RoutineLogResponse> completeBatch(Long userId, Long routineId,
                                                   RoutineCompleteBatchRequest req) {
        RoutineMst routine = findOwnedRoutine(userId, routineId);
        List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(routineId);
        if (petIds.isEmpty()) {
            throw new BusinessException(ErrorCode.ROUTINE_NO_PETS);
        }

        Instant executedAt = req.executedAt() != null ? req.executedAt() : Instant.now();
        List<RoutineLogResponse> logs = new ArrayList<>();

        for (Long petId : petIds) {
            RoutineLogResponse log = saveSingleLog(routine, petId,
                    RoutineLogStatus.COMPLETED, executedAt, req);
            logs.add(log);
        }
        routine.markExecuted(executedAt);
        return logs;
    }

    // -------------------------------------------------------------------------
    // Routine completion — individual pet
    // -------------------------------------------------------------------------

    @Transactional
    public RoutineLogResponse completeIndividual(Long userId, Long routineId,
                                                  RoutineCompleteIndividualRequest req) {
        RoutineMst routine = findOwnedRoutine(userId, routineId);
        verifyPetOwnership(userId, req.petId());

        Instant executedAt = req.executedAt() != null ? req.executedAt() : Instant.now();

        if (req.status() == RoutineLogStatus.REFUSED) {
            if (req.memo() == null || req.memo().isBlank()) {
                return null; // REFUSED without memo → no record
            }
            RoutineLogDtl log = routineLogRepository.save(RoutineLogDtl.builder()
                    .routineId(routineId)
                    .petId(req.petId())
                    .status(RoutineLogStatus.REFUSED)
                    .executedAt(executedAt)
                    .memo(req.memo())
                    .build());
            return RoutineLogResponse.from(log);
        }

        RoutineCompleteBatchRequest batchReq = new RoutineCompleteBatchRequest(
                executedAt, req.foodType(), req.amount(), req.unit(), req.feedResponse(),
                req.cleaningType(), req.weightG(), req.memo()
        );
        return saveSingleLog(routine, req.petId(),
                RoutineLogStatus.COMPLETED, executedAt, batchReq);
    }

    // -------------------------------------------------------------------------
    // Routine logs
    // -------------------------------------------------------------------------

    public List<RoutineLogResponse> listLogs(Long userId, Long routineId) {
        findOwnedRoutine(userId, routineId);
        return routineLogRepository.findAllByRoutineId(routineId)
                .stream().map(RoutineLogResponse::from).toList();
    }

    @Transactional
    public void deleteLog(Long userId, Long logId) {
        RoutineLogDtl log = routineLogRepository.findById(logId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ROUTINE_LOG_NOT_FOUND));
        RoutineMst routine = routineRepository.findById(log.getRoutineId())
                .orElseThrow(() -> new BusinessException(ErrorCode.ROUTINE_NOT_FOUND));
        if (!routine.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.ROUTINE_ACCESS_DENIED);
        }
        log.softDelete();
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    private RoutineMst findOwnedRoutine(Long userId, Long routineId) {
        RoutineMst routine = routineRepository.findById(routineId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ROUTINE_NOT_FOUND));
        if (!routine.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.ROUTINE_ACCESS_DENIED);
        }
        return routine;
    }

    private void verifyPetOwnership(Long userId, Long petId) {
        PetMst pet = petRepository.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
    }

    private RoutineLogResponse saveSingleLog(RoutineMst routine, Long petId,
                                              RoutineLogStatus status,
                                              Instant executedAt, RoutineCompleteBatchRequest req) {
        if (routine.getRoutineType() == RoutineType.FEEDING) {
            FeedingDtl feeding = feedingRepository.save(FeedingDtl.builder()
                    .petId(petId)
                    .routineId(routine.getId())
                    .foodType(req.foodType() != null ? req.foodType() : "")
                    .amount(req.amount())
                    .unit(req.unit())
                    .feedResponse(req.feedResponse())
                    .fedAt(executedAt)
                    .memo(req.memo())
                    .build());
            // Return a synthetic log response for consistency
            RoutineLogDtl log = routineLogRepository.save(RoutineLogDtl.builder()
                    .routineId(routine.getId())
                    .petId(petId)
                    .status(status)
                    .executedAt(executedAt)
                    .memo(req.memo())
                    .build());
            return RoutineLogResponse.from(log);
        }

        Map<String, Object> extraData = new HashMap<>();
        if (routine.getRoutineType() == RoutineType.CLEANING && req.cleaningType() != null) {
            extraData.put("cleaning_type", req.cleaningType());
        }
        if (routine.getRoutineType() == RoutineType.WEIGHT && req.weightG() != null) {
            extraData.put("weight_g", req.weightG());
            weightRepository.save(WeightDtl.builder()
                    .petId(petId)
                    .weightG(req.weightG())
                    .measuredAt(executedAt)
                    .source(WeightSource.MANUAL)
                    .memo(req.memo())
                    .build());
        }

        RoutineLogDtl log = routineLogRepository.save(RoutineLogDtl.builder()
                .routineId(routine.getId())
                .petId(petId)
                .status(status)
                .executedAt(executedAt)
                .extraData(extraData.isEmpty() ? null : extraData)
                .memo(req.memo())
                .build());
        return RoutineLogResponse.from(log);
    }
}
