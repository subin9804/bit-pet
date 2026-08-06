package io.bitpet.routine.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.service.PetKeeperService;
import io.bitpet.photo.repository.PhotoDtlRepository;
import io.bitpet.storage.S3Service;
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
import io.bitpet.routine.dto.FeedItemResponse;
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

import java.math.BigDecimal;
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
    private final PhotoDtlRepository photoRepository;
    private final S3Service s3Service;

    /** 개체 대표 사진 id → 표시용 URL (없으면 null) */
    private String resolvePetImageUrl(PetMst pet) {
        if (pet == null || pet.getProfilePhotoId() == null) return null;
        return photoRepository.findById(pet.getProfilePhotoId())
                .map(p -> s3Service.resolveUrl(p.getS3Key()))
                .orElse(null);
    }

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
                    resolvePetImageUrl(pet),
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
            // 미완료 — '이 개체 완료'는 안 눌렀지만 유저가 입력한 내용(급여·체중·메모 등)은 모두 저장.
            // 입력한 게 하나도 없으면 남길 것이 없으므로 기록하지 않는다.
            boolean hasData = (req.memo() != null && !req.memo().isBlank())
                    || (req.feedItems() != null && !req.feedItems().isEmpty())
                    || req.weightG() != null
                    || req.cleaningType() != null;
            if (!hasData) return null;
            RoutineCompleteBatchRequest refusedReq = new RoutineCompleteBatchRequest(
                    executedAt, req.feedItems(), req.cleaningType(), req.weightG(), req.memo()
            );
            return saveSingleLog(routine, req.petId(),
                    RoutineLogStatus.REFUSED, executedAt, refusedReq);
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
        List<RoutineLogDtl> logs = routineLogRepository.findAllByRoutineId(routineId);
        if (logs.isEmpty()) return List.of();

        List<Long> logIds = logs.stream().map(RoutineLogDtl::getId).toList();

        // 로그별 급여 항목·메모·체중 (routine_log_id 로 연결된 dtl 에서 파생)
        Map<Long, List<FeedItemResponse>> feedByLog = new HashMap<>();
        Map<Long, String> memoByLog = new HashMap<>();
        Map<Long, java.math.BigDecimal> weightByLog = new HashMap<>();
        for (FeedingDtl d : feedingRepository.findByRoutineLogIdIn(logIds)) {
            feedByLog.computeIfAbsent(d.getRoutineLogId(), k -> new ArrayList<>())
                    .add(FeedItemResponse.from(d));
            if (d.getMemo() != null) memoByLog.putIfAbsent(d.getRoutineLogId(), d.getMemo());
        }
        for (WeightDtl d : weightRepository.findByRoutineLogIdIn(logIds)) {
            weightByLog.putIfAbsent(d.getRoutineLogId(), d.getWeightG());
            if (d.getMemo() != null) memoByLog.putIfAbsent(d.getRoutineLogId(), d.getMemo());
        }
        for (CleaningDtl d : cleaningRepository.findByRoutineLogIdIn(logIds)) {
            if (d.getMemo() != null) memoByLog.putIfAbsent(d.getRoutineLogId(), d.getMemo());
        }
        // 미완료·커스텀 메모는 memo_dtl 에 저장됨
        for (MemoDtl d : memoRepository.findByRoutineLogIdIn(logIds)) {
            memoByLog.putIfAbsent(d.getRoutineLogId(), d.getContent());
        }

        return logs.stream()
                .map(l -> RoutineLogResponse.from(l, memoByLog.get(l.getId()),
                        weightByLog.get(l.getId()),
                        feedByLog.getOrDefault(l.getId(), List.of())))
                .toList();
    }

    @Transactional
    public void deleteLog(Long userId, Long logId) {
        RoutineLogDtl log = routineLogRepository.findById(logId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ROUTINE_LOG_NOT_FOUND));
        findAccessibleRoutine(userId, log.getRoutineId());
        // 이 로그에 연결된 짝 기록(급여·체중·청소·메모)도 함께 정리 —
        // 취소 시 기록이 남거나 재저장 시 중복되는 것을 방지
        deletePairedDtl(logId);
        routineLogRepository.delete(log);
    }

    /** routine_log_id 로 연결된 도메인 기록을 soft delete */
    private void deletePairedDtl(Long logId) {
        feedingRepository.findByRoutineLogId(logId).forEach(FeedingDtl::softDelete);
        weightRepository.findByRoutineLogId(logId).forEach(WeightDtl::softDelete);
        cleaningRepository.findByRoutineLogId(logId).forEach(CleaningDtl::softDelete);
        memoRepository.findByRoutineLogId(logId).forEach(MemoDtl::softDelete);
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
        // 체중 실측값은 '완료(COMPLETED)'에서만 필수. 미완료는 값 없으면 체중 기록만 생략.
        if (status == RoutineLogStatus.COMPLETED
                && routine.getRoutineType() == RoutineType.WEIGHT && req.weightG() == null) {
            throw new BusinessException(ErrorCode.ROUTINE_WEIGHT_REQUIRED);
        }

        final Long userId = routine.getUserId();
        final String memo = (req.memo() != null && !req.memo().isBlank()) ? req.memo() : null;

        // 1) 로그를 먼저 저장해 dtl 이 참조할 id 확보 (memo 는 dtl 에 저장)
        RoutineLogDtl log = routineLogRepository.save(RoutineLogDtl.builder()
                .routineId(routine.getId())
                .petId(petId)
                .createdByUserId(userId)
                .status(status)
                .executedAt(executedAt)
                .build());
        Long logId = log.getId();

        List<FeedItemResponse> feedItems = List.of();
        boolean memoStored = false; // 메모를 담은 dtl 이 생성됐는지

        switch (routine.getRoutineType()) {
            case FEEDING -> {
                List<FeedItemRequest> items = req.feedItems() != null ? req.feedItems() : List.of();
                List<FeedItemResponse> saved = new ArrayList<>();
                for (FeedItemRequest item : items) {
                    FeedingDtl d = feedingRepository.save(FeedingDtl.builder()
                            .petId(petId)
                            .routineId(routine.getId())
                            .routineLogId(logId)
                            .createdByUserId(userId)
                            .refused(item.isRefused())
                            // 거식이면 엔티티가 먹이 정보를 비운다 — 여기서 넘겨도 무시된다
                            .foodType(item.foodType() != null ? item.foodType() : "")
                            .amount(item.amount())
                            .unit(item.unit())
                            .sizeLabel(item.sizeLabel())
                            .supplement(item.supplement())
                            .fedAt(executedAt)
                            .memo(memo)
                            .build());
                    saved.add(FeedItemResponse.from(d));
                }
                feedItems = saved;
                if (!items.isEmpty()) memoStored = true;
            }
            case CLEANING -> {
                CleaningType cleaningType = req.cleaningType() != null
                        ? CleaningType.valueOf(req.cleaningType())
                        : CleaningType.FULL;
                cleaningRepository.save(CleaningDtl.builder()
                        .petId(petId)
                        .routineId(routine.getId())
                        .routineLogId(logId)
                        .createdByUserId(userId)
                        .cleaningType(cleaningType)
                        .cleanedAt(executedAt)
                        .memo(memo)
                        .build());
                memoStored = true;
            }
            case WEIGHT -> {
                // 미완료는 값이 없을 수 있음 — 값이 있을 때만 체중 기록
                if (req.weightG() != null) {
                    weightRepository.save(WeightDtl.builder()
                            .petId(petId)
                            .routineId(routine.getId())
                            .routineLogId(logId)
                            .createdByUserId(userId)
                            .weightG(req.weightG())
                            .measuredAt(executedAt)
                            .source(WeightSource.MANUAL)
                            .memo(memo)
                            .build());
                    memoStored = true;
                }
            }
            case CUSTOM -> {
                if (memo != null) {
                    memoRepository.save(MemoDtl.builder()
                            .petId(petId)
                            .routineId(routine.getId())
                            .routineLogId(logId)
                            .createdByUserId(userId)
                            .content(memo)
                            .loggedAt(executedAt)
                            .build());
                    memoStored = true;
                }
            }
        }
        // 메모는 있는데 담을 dtl 이 없었으면 memo_dtl 에 보관 (급여항목 없는 완료, 값 없는 체중 미완료 등)
        if (memo != null && !memoStored) {
            memoRepository.save(MemoDtl.builder()
                    .petId(petId).routineId(routine.getId()).routineLogId(logId)
                    .createdByUserId(userId).content(memo).loggedAt(executedAt).build());
        }
        BigDecimal weightG = routine.getRoutineType() == RoutineType.WEIGHT ? req.weightG() : null;
        return RoutineLogResponse.from(log, memo, weightG, feedItems);
    }
}
