package io.bitpet.record.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.record.domain.CleaningDtl;
import io.bitpet.record.domain.FeedingDtl;
import io.bitpet.record.domain.WeightDtl;
import io.bitpet.record.dto.CleaningCreateRequest;
import io.bitpet.record.dto.CleaningResponse;
import io.bitpet.record.dto.CleaningUpdateRequest;
import io.bitpet.record.dto.FeedingCreateRequest;
import io.bitpet.record.dto.FeedingResponse;
import io.bitpet.record.dto.FeedingUpdateRequest;
import io.bitpet.record.dto.RecentRecordResponse;
import io.bitpet.record.dto.WeightCreateRequest;
import io.bitpet.record.dto.WeightResponse;
import io.bitpet.record.laying.domain.LayingDtl;
import io.bitpet.record.laying.repository.LayingDtlRepository;
import io.bitpet.record.mating.domain.MatingDtl;
import io.bitpet.record.mating.repository.MatingDtlRepository;
import io.bitpet.record.memo.domain.MemoDtl;
import io.bitpet.record.memo.repository.MemoDtlRepository;
import io.bitpet.record.repository.CleaningDtlRepository;
import io.bitpet.record.repository.FeedingDtlRepository;
import io.bitpet.record.repository.WeightDtlRepository;
import io.bitpet.routine.domain.RoutineLogDtl;
import io.bitpet.routine.domain.RoutineType;
import io.bitpet.routine.repository.RoutineLogDtlRepository;
import io.bitpet.routine.repository.RoutineMstRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RecordService {

    private final PetMstRepository petRepository;
    private final WeightDtlRepository weightRepository;
    private final FeedingDtlRepository feedingRepository;
    private final CleaningDtlRepository cleaningRepository;
    private final MemoDtlRepository memoRepository;
    private final MatingDtlRepository matingRepository;
    private final LayingDtlRepository layingRepository;
    private final RoutineLogDtlRepository routineLogRepository;
    private final RoutineMstRepository routineRepository;

    // -------------------------------------------------------------------------
    // Weight
    // -------------------------------------------------------------------------

    public List<WeightResponse> listWeights(Long userId, Long petId) {
        verifyPetOwnership(userId, petId);
        return weightRepository.findAllByPetIdOrderByMeasuredAtDesc(petId)
                .stream().map(WeightResponse::from).toList();
    }

    @Transactional
    public WeightResponse addWeight(Long userId, Long petId, WeightCreateRequest req) {
        verifyPetOwnership(userId, petId);
        WeightDtl saved = weightRepository.save(WeightDtl.builder()
                .petId(petId)
                .weightG(req.weightG())
                .measuredAt(req.measuredAt())
                .source(req.source())
                .memo(req.memo())
                .build());
        return WeightResponse.from(saved);
    }

    @Transactional
    public void deleteWeight(Long userId, Long weightId) {
        WeightDtl weight = weightRepository.findById(weightId)
                .orElseThrow(() -> new BusinessException(ErrorCode.WEIGHT_NOT_FOUND));
        verifyPetOwnership(userId, weight.getPetId());
        weight.softDelete();
    }

    // -------------------------------------------------------------------------
    // Feeding
    // -------------------------------------------------------------------------

    public List<FeedingResponse> listFeedings(Long userId, Long petId) {
        verifyPetOwnership(userId, petId);
        return feedingRepository.findAllByPetIdOrderByFedAtDesc(petId)
                .stream().map(FeedingResponse::from).toList();
    }

    @Transactional
    public FeedingResponse addFeeding(Long userId, Long petId, FeedingCreateRequest req) {
        verifyPetOwnership(userId, petId);
        FeedingDtl saved = feedingRepository.save(FeedingDtl.builder()
                .petId(petId)
                .foodType(req.foodType())
                .amount(req.amount())
                .unit(req.unit())
                .sizeLabel(req.sizeLabel())
                .supplement(req.supplement())
                .fedAt(req.fedAt())
                .memo(req.memo())
                .build());
        return FeedingResponse.from(saved);
    }

    @Transactional
    public FeedingResponse updateFeeding(Long userId, Long feedingId, FeedingUpdateRequest req) {
        FeedingDtl feeding = feedingRepository.findById(feedingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.FEEDING_NOT_FOUND));
        verifyPetOwnership(userId, feeding.getPetId());
        feeding.update(req.foodType(), req.amount(), req.unit(), req.sizeLabel(), req.supplement(), req.fedAt(), req.memo());
        return FeedingResponse.from(feeding);
    }

    @Transactional
    public void deleteFeeding(Long userId, Long feedingId) {
        FeedingDtl feeding = feedingRepository.findById(feedingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.FEEDING_NOT_FOUND));
        verifyPetOwnership(userId, feeding.getPetId());
        feeding.softDelete();
    }

    // -------------------------------------------------------------------------
    // Cleaning
    // -------------------------------------------------------------------------

    public List<CleaningResponse> listCleanings(Long userId, Long petId) {
        verifyPetOwnership(userId, petId);
        return cleaningRepository.findAllByPetIdOrderByCleanedAtDesc(petId)
                .stream().map(CleaningResponse::from).toList();
    }

    @Transactional
    public CleaningResponse addCleaning(Long userId, Long petId, CleaningCreateRequest req) {
        verifyPetOwnership(userId, petId);
        CleaningDtl saved = cleaningRepository.save(CleaningDtl.builder()
                .petId(petId)
                .cleaningType(req.cleaningType())
                .cleanedAt(req.cleanedAt())
                .memo(req.memo())
                .build());
        return CleaningResponse.from(saved);
    }

    @Transactional
    public CleaningResponse updateCleaning(Long userId, Long cleaningId, CleaningUpdateRequest req) {
        CleaningDtl cleaning = cleaningRepository.findById(cleaningId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CLEANING_NOT_FOUND));
        verifyPetOwnership(userId, cleaning.getPetId());
        cleaning.update(req.cleaningType(), req.cleanedAt(), req.memo());
        return CleaningResponse.from(cleaning);
    }

    @Transactional
    public void deleteCleaning(Long userId, Long cleaningId) {
        CleaningDtl cleaning = cleaningRepository.findById(cleaningId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CLEANING_NOT_FOUND));
        verifyPetOwnership(userId, cleaning.getPetId());
        cleaning.softDelete();
    }

    // -------------------------------------------------------------------------
    // Recent records — aggregated feed
    // -------------------------------------------------------------------------

    public List<RecentRecordResponse> getRecentRecords(Long userId, int limit) {
        List<PetMst> pets = petRepository.findAllByUserId(userId);
        if (pets.isEmpty()) return List.of();

        List<Long> petIds = pets.stream().map(PetMst::getId).toList();
        Map<Long, String> petNameMap  = pets.stream()
                .collect(Collectors.toMap(PetMst::getId, PetMst::getName));
        Map<Long, String> petColorMap = pets.stream()
                .collect(Collectors.toMap(PetMst::getId,
                        p -> p.getColorCode() != null ? p.getColorCode() : ""));

        PageRequest page = PageRequest.of(0, limit);
        List<RecentRecordResponse> all = new ArrayList<>();

        feedingRepository.findAllByPetIdInOrderByFedAtDesc(petIds, page).forEach(f ->
                all.add(RecentRecordResponse.of("FEEDING", f.getId(), f.getPetId(),
                        petNameMap.getOrDefault(f.getPetId(), ""),
                        petColorMap.get(f.getPetId()),
                        f.getFedAt(), buildFeedingSummary(f), f.getMemo())));

        weightRepository.findAllByPetIdInOrderByMeasuredAtDesc(petIds, page).forEach(w ->
                all.add(RecentRecordResponse.of("WEIGHT", w.getId(), w.getPetId(),
                        petNameMap.getOrDefault(w.getPetId(), ""),
                        petColorMap.get(w.getPetId()),
                        w.getMeasuredAt(), w.getWeightG() + "g", w.getMemo())));

        cleaningRepository.findAllByPetIdInOrderByCleanedAtDesc(petIds, page).forEach(c ->
                all.add(RecentRecordResponse.of("CLEANING", c.getId(), c.getPetId(),
                        petNameMap.getOrDefault(c.getPetId(), ""),
                        petColorMap.get(c.getPetId()),
                        c.getCleanedAt(), c.getCleaningType() != null ? c.getCleaningType().name() : "", c.getMemo())));

        memoRepository.findAllByPetIdInOrderByLoggedAtDesc(petIds, page).forEach(m ->
                all.add(RecentRecordResponse.of("MEMO", m.getId(), m.getPetId(),
                        petNameMap.getOrDefault(m.getPetId(), ""),
                        petColorMap.get(m.getPetId()),
                        m.getLoggedAt(), truncate(m.getContent(), 50), m.getContent())));

        all.sort(Comparator.comparing(RecentRecordResponse::createdAt).reversed());
        return all.subList(0, Math.min(limit, all.size()));
    }

    public List<RecentRecordResponse> getRecordsByDate(Long userId, LocalDate date) {
        List<PetMst> pets = petRepository.findAllByUserId(userId);
        if (pets.isEmpty()) return List.of();

        List<Long> petIds = pets.stream().map(PetMst::getId).toList();
        Set<Long> petIdSet = Set.copyOf(petIds);
        Map<Long, String> petNameMap  = pets.stream()
                .collect(Collectors.toMap(PetMst::getId, PetMst::getName));
        Map<Long, String> petColorMap = pets.stream()
                .collect(Collectors.toMap(PetMst::getId,
                        p -> p.getColorCode() != null ? p.getColorCode() : ""));

        Instant from = date.atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant to   = date.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();

        List<RecentRecordResponse> all = new ArrayList<>();

        // FEEDING: feeding_dtl (루틴 완료 + 단독 모두 포함)
        feedingRepository.findAllByPetIdInAndFedAtBetweenOrderByFedAtDesc(petIds, from, to)
                .forEach(f -> all.add(RecentRecordResponse.of(
                        "FEEDING", f.getId(), f.getPetId(),
                        petNameMap.getOrDefault(f.getPetId(), ""),
                        petColorMap.get(f.getPetId()),
                        f.getFedAt(), buildFeedingSummary(f), f.getMemo())));

        // WEIGHT: weight_dtl (루틴 완료 + 단독 모두 포함)
        weightRepository.findAllByPetIdInAndMeasuredAtBetweenOrderByMeasuredAtDesc(petIds, from, to)
                .forEach(w -> all.add(RecentRecordResponse.of(
                        "WEIGHT", w.getId(), w.getPetId(),
                        petNameMap.getOrDefault(w.getPetId(), ""),
                        petColorMap.get(w.getPetId()),
                        w.getMeasuredAt(), w.getWeightG() + "g", w.getMemo())));

        // CLEANING: cleaning_dtl(단독) + routine_log_dtl(루틴 CLEANING 완료)
        cleaningRepository.findAllByPetIdInAndCleanedAtBetweenOrderByCleanedAtDesc(petIds, from, to)
                .forEach(c -> all.add(RecentRecordResponse.of(
                        "CLEANING", c.getId(), c.getPetId(),
                        petNameMap.getOrDefault(c.getPetId(), ""),
                        petColorMap.get(c.getPetId()),
                        c.getCleanedAt(),
                        c.getCleaningType() != null ? c.getCleaningType().name() : "",
                        c.getMemo())));
        routineLogRepository.findCompletedByPetIdsAndRoutineTypeAndDateRange(petIds, RoutineType.CLEANING, from, to)
                .forEach(r -> all.add(RecentRecordResponse.of(
                        "CLEANING", r.getId(), r.getPetId(),
                        petNameMap.getOrDefault(r.getPetId(), ""),
                        petColorMap.get(r.getPetId()),
                        r.getExecutedAt(), "루틴 청소", r.getMemo())));

        // MEMO
        memoRepository.findAllByPetIdInAndLoggedAtBetweenOrderByLoggedAtDesc(petIds, from, to)
                .forEach(m -> all.add(RecentRecordResponse.of(
                        "MEMO", m.getId(), m.getPetId(),
                        petNameMap.getOrDefault(m.getPetId(), ""),
                        petColorMap.get(m.getPetId()),
                        m.getLoggedAt(), truncate(m.getContent(), 50), m.getContent())));

        // MATING: 교배 양쪽 개체 모두 표시 (한 교배당 최대 2개 칩)
        matingRepository.findByPetIdsAndDateRange(petIds, from, to).forEach(m -> {
            String maleName  = m.getMalePetId()   != null ? petNameMap.getOrDefault(m.getMalePetId(), "외부") : "외부";
            String femaleName = m.getFemalePetId() != null ? petNameMap.getOrDefault(m.getFemalePetId(), "외부") : "외부";
            String petName = maleName + " × " + femaleName;
            // 대표 petId: 소유 개체 중 하나
            Long repPetId = (m.getMalePetId() != null && petIdSet.contains(m.getMalePetId()))
                    ? m.getMalePetId() : m.getFemalePetId();
            String colorCode = repPetId != null ? petColorMap.get(repPetId) : null;
            all.add(RecentRecordResponse.of("MATING", m.getId(), repPetId,
                    petName, colorCode, m.getTriedAt(), "교배", m.getMemo()));
        });

        // LAYING
        layingRepository.findByPetIdsAndDateRange(petIds, from, to).forEach(l -> {
            String summary = l.getEggCountTotal() + "개 산란";
            all.add(RecentRecordResponse.of("LAYING", l.getId(), l.getPetId(),
                    petNameMap.getOrDefault(l.getPetId(), ""),
                    petColorMap.get(l.getPetId()),
                    l.getLaidAt(), summary, l.getMemo()));
        });

        all.sort(Comparator.comparing(RecentRecordResponse::createdAt).reversed());
        return all;
    }

    private String buildFeedingSummary(FeedingDtl f) {
        StringBuilder sb = new StringBuilder(f.getFoodType() != null ? f.getFoodType() : "");
        if (f.getAmount() != null) {
            sb.append(" ").append(f.getAmount().stripTrailingZeros().toPlainString());
            if (f.getUnit() != null) sb.append(f.getUnit());
        }
        return sb.toString().trim();
    }

    private static String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() > max ? s.substring(0, max) + "…" : s;
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    private void verifyPetOwnership(Long userId, Long petId) {
        PetMst pet = petRepository.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.RECORD_ACCESS_DENIED);
        }
    }
}
