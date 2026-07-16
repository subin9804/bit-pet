package io.bitpet.routine.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.service.PetKeeperService;
import io.bitpet.record.domain.CleaningDtl;
import io.bitpet.record.domain.CleaningType;
import io.bitpet.record.domain.FeedingDtl;
import io.bitpet.record.domain.WeightDtl;
import io.bitpet.record.domain.WeightSource;
import io.bitpet.record.memo.domain.MemoDtl;
import io.bitpet.record.memo.repository.MemoDtlRepository;
import io.bitpet.record.repository.CleaningDtlRepository;
import io.bitpet.record.repository.FeedingDtlRepository;
import io.bitpet.record.repository.WeightDtlRepository;
import io.bitpet.routine.domain.RoutineLogDtl;
import io.bitpet.routine.domain.RoutineLogStatus;
import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.domain.RoutinePetRls;
import io.bitpet.routine.domain.RoutineType;
import io.bitpet.routine.dto.RoutineCompleteBatchRequest;
import io.bitpet.routine.dto.RoutineCompleteIndividualRequest;
import io.bitpet.routine.dto.FeedItemRequest;
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
import java.time.ZoneId;
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
    private final CleaningDtlRepository cleaningRepository;
    private final MemoDtlRepository memoRepository;
    private final PetKeeperService petKeeper;
    private final RoutineMaintenanceService routineMaintenance;

    // -------------------------------------------------------------------------
    // Routine CRUD (생성자 개인 소유 — 본인이 만든 루틴만 조회·수정 가능)
    // -------------------------------------------------------------------------

    @Transactional
    public List<RoutineResponse> listRoutines(Long userId) {
        LocalDate today = LocalDate.now(SEOUL);
        List<RoutineMst> routines = loadRoutines(userId);
        catchUpOverdue(routines, today);
        return routines.stream().map(r -> {
            List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(r.getId());
            return RoutineResponse.from(r, petIds);
        }).toList();
    }

    @Transactional
    public RoutineResponse getRoutine(Long userId, Long routineId) {
        RoutineMst routine = findAccessibleRoutine(userId, routineId);
        catchUpOverdue(List.of(routine), LocalDate.now(SEOUL));
        List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(routineId);
        return RoutineResponse.from(routine, petIds);
    }

    /**
     * 예정일이 지난 미완료 루틴을 오늘 이후가 될 때까지 다음 주기로 전진.
     * 자정 배치(rollOverPastDueRoutines)가 서버 다운 등으로 미실행돼도 조회 시점에 자가 치유.
     */
    private void catchUpOverdue(List<RoutineMst> routines, LocalDate today) {
        routines.forEach(r -> {
            if (r.getNextDueAt() != null && r.getNextDueAt().isBefore(today)) {
                r.advanceDueDate();
            }
        });
    }

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    @Transactional
    public RoutineResponse createRoutine(Long userId, RoutineCreateRequest req) {
        LocalDate nextDueAt = req.startAt() != null
                ? req.startAt().atZone(SEOUL).toLocalDate()
                : LocalDate.now(SEOUL).plusDays(req.cycleDays());

        RoutineMst saved = routineRepository.save(RoutineMst.builder()
                .userId(userId)
                .routineType(req.routineType())
                .title(req.title())
                .cycleDays(req.cycleDays())
                .alarmTime(req.alarmTime())
                .alarmEnabled(req.alarmEnabled())
                .startDate(nextDueAt)   // 시작일 = 첫 예정일 (이후 nextDueAt만 전진)
                .nextDueAt(nextDueAt)
                .memo(req.memo())
                .build());

        List<Long> petIds = new ArrayList<>();
        if (req.petIds() != null) {
            for (Long petId : req.petIds()) {
                verifyPetAccessible(userId, petId);
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
        RoutineMst routine = findAccessibleRoutine(userId, routineId);
        routine.update(req.routineType(), req.title(), req.cycleDays(),
                req.alarmTime(), req.alarmEnabled(), req.active(), req.memo());
        List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(routineId);
        return RoutineResponse.from(routine, petIds);
    }

    @Transactional
    public void deleteRoutine(Long userId, Long routineId) {
        RoutineMst routine = findAccessibleRoutine(userId, routineId);
        // soft delete — hard delete 시 routine_log_dtl FK(CASCADE)가 실행 기록을 함께 지움
        routine.softDelete();
    }

    // -------------------------------------------------------------------------
    // Pet subscription (routine_pet_rls)
    // -------------------------------------------------------------------------

    @Transactional
    public void subscribePet(Long userId, Long routineId, Long petId) {
        findAccessibleRoutine(userId, routineId);
        verifyPetAccessible(userId, petId);
        if (!routinePetRepository.existsByRoutineIdAndPetId(routineId, petId)) {
            routinePetRepository.save(RoutinePetRls.builder()
                    .routineId(routineId)
                    .petId(petId)
                    .build());
        }
        // 연결된 '내' 개체가 생겼으므로 활성 재계산 (0→1이면 활성화)
        routineMaintenance.refreshActive(routineId);
    }

    @Transactional
    public void unsubscribePet(Long userId, Long routineId, Long petId) {
        findAccessibleRoutine(userId, routineId);
        routinePetRepository.deleteByRoutineIdAndPetId(routineId, petId);
        // 연결이 0개가 되면 비활성화
        routineMaintenance.refreshActive(routineId);
    }

    public List<Long> listSubscribedPets(Long userId, Long routineId) {
        findAccessibleRoutine(userId, routineId);
        return routinePetRepository.findPetIdsByRoutineId(routineId);
    }

    // -------------------------------------------------------------------------
    // Today's routines — completion status per pet
    // -------------------------------------------------------------------------

    @Transactional
    public List<TodayRoutineResponse> listTodayRoutines(Long userId) {
        LocalDate today = LocalDate.now(SEOUL);
        Instant[] todayRange = todayRange(today);
        List<RoutineMst> routines = loadActiveRoutines(userId);
        // 자정 스케줄러가 미실행된 경우 즉석 catchup
        catchUpOverdue(routines, today);
        return routines.stream()
                .filter(r -> r.getNextDueAt() != null && isDueOrCompletedToday(r, today))
                .map(r -> {
                    List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(r.getId());
                    return TodayRoutineResponse.from(r, buildPetTodayStatuses(r.getId(), petIds, todayRange[0], todayRange[1]));
                }).toList();
    }

    /** 오늘 예정(nextDueAt == today) 또는 오늘 완료(lastExecutedAt == today) */
    private static boolean isDueOrCompletedToday(RoutineMst r, LocalDate today) {
        boolean dueToday       = today.equals(r.getNextDueAt());
        boolean completedToday = today.equals(r.getLastExecutedAt());
        return dueToday || completedToday;
    }

    public TodayRoutineResponse getTodayRoutineStatus(Long userId, Long routineId) {
        RoutineMst routine = findAccessibleRoutine(userId, routineId);
        LocalDate today = LocalDate.now(SEOUL);
        Instant[] todayRange = todayRange(today);
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
            String petName     = pet != null ? pet.getName() : "";
            String speciesName = (pet != null && pet.getSpecies() != null)
                    ? pet.getSpecies().getNameKo() : "";
            String colorCode   = pet != null ? pet.getColorCode() : null;
            RoutineLogDtl log  = logByPetId.get(petId);
            return new TodayRoutineResponse.PetTodayStatus(
                    petId, petName, speciesName, colorCode,
                    log != null,
                    log != null ? log.getId() : null
            );
        }).toList();
    }

    private static Instant[] todayRange(LocalDate today) {
        Instant from = today.atStartOfDay(SEOUL).toInstant();
        Instant to   = today.plusDays(1).atStartOfDay(SEOUL).toInstant();
        return new Instant[]{from, to};
    }

    // -------------------------------------------------------------------------
    // Pet view: routines with subscription status
    // -------------------------------------------------------------------------

    @Transactional
    public List<RoutineWithSubscriptionResponse> listRoutinesForPet(Long userId, Long petId) {
        verifyPetAccessible(userId, petId);
        LocalDate today = LocalDate.now(SEOUL);
        Instant[] todayRange = todayRange(today);
        List<RoutineMst> routines = loadActiveRoutines(userId);
        catchUpOverdue(routines, today);
        return routines.stream()
                .filter(r -> routinePetRepository.existsByRoutineIdAndPetId(r.getId(), petId))
                .map(r -> {
                    List<Long> petIds = routinePetRepository.findPetIdsByRoutineId(r.getId());
                    List<RoutineLogDtl> todayLogs = routineLogRepository.findTodayLogs(
                            r.getId(), petId, todayRange[0], todayRange[1]);
                    RoutineLogDtl todayLog = todayLogs.stream().findFirst().orElse(null);
                    return new RoutineWithSubscriptionResponse(
                            RoutineResponse.from(r, petIds),
                            true,
                            todayLog != null,
                            todayLog != null ? todayLog.getId() : null
                    );
                }).toList();
    }

    public record RoutineWithSubscriptionResponse(
            RoutineResponse routine,
            boolean subscribed,
            boolean todayCompleted,
            Long todayLogId
    ) {}

    // -------------------------------------------------------------------------
    // Routine completion — batch (all pets, same data)
    // -------------------------------------------------------------------------

    @Transactional
    public List<RoutineLogResponse> completeBatch(Long userId, Long routineId,
                                                   RoutineCompleteBatchRequest req) {
        RoutineMst routine = findAccessibleRoutine(userId, routineId);
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
        RoutineMst routine = findAccessibleRoutine(userId, routineId);
        verifyPetAccessible(userId, req.petId());

        Instant executedAt = req.executedAt() != null ? req.executedAt() : Instant.now();

        if (req.status() == RoutineLogStatus.REFUSED) {
            if (req.memo() == null || req.memo().isBlank()) {
                return null; // REFUSED without memo → no record
            }
            RoutineLogDtl log = routineLogRepository.save(RoutineLogDtl.builder()
                    .routineId(routineId)
                    .petId(req.petId())
                    .createdByUserId(userId)
                    .status(RoutineLogStatus.REFUSED)
                    .executedAt(executedAt)
                    .memo(req.memo())
                    .build());
            return RoutineLogResponse.from(log);
        }

        RoutineCompleteBatchRequest batchReq = new RoutineCompleteBatchRequest(
                executedAt, req.feedItems(), req.cleaningType(), req.weightG(), req.memo()
        );
        return saveSingleLog(routine, req.petId(),
                RoutineLogStatus.COMPLETED, executedAt, batchReq);
    }

    // -------------------------------------------------------------------------
    // Routine logs
    // -------------------------------------------------------------------------

    public List<RoutineLogResponse> listLogs(Long userId, Long routineId) {
        findAccessibleRoutine(userId, routineId);
        return routineLogRepository.findAllByRoutineId(routineId)
                .stream().map(RoutineLogResponse::from).toList();
    }

    @Transactional
    public void deleteLog(Long userId, Long logId) {
        RoutineLogDtl log = routineLogRepository.findById(logId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ROUTINE_LOG_NOT_FOUND));
        RoutineMst routine = findAccessibleRoutine(userId, log.getRoutineId());
        // 완료와 함께 생성된 짝 기록(급여·체중·청소·메모)도 함께 정리 —
        // 취소 시 기록이 남거나 재저장 시 중복되는 것을 방지
        deletePairedDtl(routine, log.getPetId(), log.getExecutedAt());
        routineLogRepository.delete(log);
    }

    /** 루틴 완료 로그와 동일 시각으로 생성된 도메인 기록을 soft delete */
    private void deletePairedDtl(RoutineMst routine, Long petId, Instant executedAt) {
        if (executedAt == null) return;
        switch (routine.getRoutineType()) {
            case FEEDING -> feedingRepository
                    .findAllByRoutineIdAndPetIdAndFedAt(routine.getId(), petId, executedAt)
                    .forEach(FeedingDtl::softDelete);
            case WEIGHT -> weightRepository
                    .findAllByRoutineIdAndPetIdAndMeasuredAt(routine.getId(), petId, executedAt)
                    .forEach(WeightDtl::softDelete);
            case CLEANING -> cleaningRepository
                    .findAllByRoutineIdAndPetIdAndCleanedAt(routine.getId(), petId, executedAt)
                    .forEach(CleaningDtl::softDelete);
            case CUSTOM -> memoRepository
                    .findAllByRoutineIdAndPetIdAndLoggedAt(routine.getId(), petId, executedAt)
                    .forEach(MemoDtl::softDelete);
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers — 생성자 개인 소유 기반 조회·접근제어
    // -------------------------------------------------------------------------

    /** 본인이 만든 루틴 전체 */
    private List<RoutineMst> loadRoutines(Long userId) {
        return routineRepository.findAllByUserIdOrderByCreatedAtDesc(userId);
    }

    /** loadRoutines 의 active=true 버전 */
    private List<RoutineMst> loadActiveRoutines(Long userId) {
        return routineRepository.findAllByUserIdAndActiveOrderByCreatedAtDesc(userId, true);
    }

    /** 접근 가능한 루틴 조회 — 생성자 본인만 */
    private RoutineMst findAccessibleRoutine(Long userId, Long routineId) {
        RoutineMst routine = routineRepository.findById(routineId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ROUTINE_NOT_FOUND));
        if (!routine.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.ROUTINE_ACCESS_DENIED);
        }
        return routine;
    }

    /** 접근 가능한 개체인지 검증 — 공유 개체 포함, 사육자(OWNER/KEEPER)면 루틴 적용 가능 */
    private void verifyPetAccessible(Long userId, Long petId) {
        petKeeper.assertKeeper(userId, petId);
    }

    private RoutineLogResponse saveSingleLog(RoutineMst routine, Long petId,
                                              RoutineLogStatus status,
                                              Instant executedAt, RoutineCompleteBatchRequest req) {
        if (routine.getRoutineType() == RoutineType.FEEDING) {
            List<FeedItemRequest> items = req.feedItems() != null ? req.feedItems() : List.of();
            for (FeedItemRequest item : items) {
                feedingRepository.save(FeedingDtl.builder()
                        .petId(petId)
                        .routineId(routine.getId())
                        .createdByUserId(routine.getUserId())
                        .foodType(item.foodType() != null ? item.foodType() : "")
                        .amount(item.amount())
                        .unit(item.unit())
                        .sizeLabel(item.sizeLabel())
                        .supplement(item.supplement())
                        .fedAt(executedAt)
                        .memo(req.memo())
                        .build());
            }
            RoutineLogDtl log = routineLogRepository.save(RoutineLogDtl.builder()
                    .routineId(routine.getId())
                    .petId(petId)
                    .createdByUserId(routine.getUserId())
                    .status(status)
                    .executedAt(executedAt)
                    .memo(req.memo())
                    .build());
            return RoutineLogResponse.from(log);
        }

        if (routine.getRoutineType() == RoutineType.CLEANING) {
            CleaningType cleaningType = req.cleaningType() != null
                    ? CleaningType.valueOf(req.cleaningType())
                    : CleaningType.FULL;
            cleaningRepository.save(CleaningDtl.builder()
                    .petId(petId)
                    .routineId(routine.getId())
                    .createdByUserId(routine.getUserId())
                    .cleaningType(cleaningType)
                    .cleanedAt(executedAt)
                    .memo(req.memo())
                    .build());
        }

        if (routine.getRoutineType() == RoutineType.WEIGHT) {
            // 체중 기록은 실측값이 필수 — 빈값 완료는 기록이 아님
            if (req.weightG() == null) {
                throw new BusinessException(ErrorCode.ROUTINE_WEIGHT_REQUIRED);
            }
            weightRepository.save(WeightDtl.builder()
                    .petId(petId)
                    .routineId(routine.getId())
                    .createdByUserId(routine.getUserId())
                    .weightG(req.weightG())
                    .measuredAt(executedAt)
                    .source(WeightSource.MANUAL)
                    .memo(req.memo())
                    .build());
        }

        if (routine.getRoutineType() == RoutineType.CUSTOM
                && req.memo() != null && !req.memo().isBlank()) {
            memoRepository.save(MemoDtl.builder()
                    .petId(petId)
                    .routineId(routine.getId())
                    .createdByUserId(routine.getUserId())
                    .content(req.memo())
                    .loggedAt(executedAt)
                    .build());
        }

        RoutineLogDtl log = routineLogRepository.save(RoutineLogDtl.builder()
                .routineId(routine.getId())
                .petId(petId)
                .createdByUserId(routine.getUserId())
                .status(status)
                .executedAt(executedAt)
                .build());
        return RoutineLogResponse.from(log);
    }
}
