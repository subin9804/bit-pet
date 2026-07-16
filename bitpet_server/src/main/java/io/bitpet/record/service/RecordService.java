package io.bitpet.record.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.record.domain.CleaningDtl;
import io.bitpet.record.domain.CleaningType;
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
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.jdbc.core.JdbcTemplate;
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
    private final io.bitpet.pet.service.PetKeeperService petKeeper;
    private final WeightDtlRepository weightRepository;
    private final FeedingDtlRepository feedingRepository;
    private final CleaningDtlRepository cleaningRepository;
    private final MemoDtlRepository memoRepository;
    private final MatingDtlRepository matingRepository;
    private final LayingDtlRepository layingRepository;
    private final JdbcTemplate jdbc;


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
                .createdByUserId(userId)
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
                .createdByUserId(userId)
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
                .createdByUserId(userId)
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
                        c.getCleanedAt(), cleaningTypeKo(c.getCleaningType()), c.getMemo())));

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

        // CLEANING: cleaning_dtl (루틴 완료 + 단독 모두 포함 — routine_id 유무로 구분 가능)
        cleaningRepository.findAllByPetIdInAndCleanedAtBetweenOrderByCleanedAtDesc(petIds, from, to)
                .forEach(c -> all.add(RecentRecordResponse.of(
                        "CLEANING", c.getId(), c.getPetId(),
                        petNameMap.getOrDefault(c.getPetId(), ""),
                        petColorMap.get(c.getPetId()),
                        c.getCleanedAt(),
                        cleaningTypeKo(c.getCleaningType()),
                        c.getMemo())));

        // MEMO: memo_dtl (루틴 CUSTOM 완료 메모 + 단독 메모 모두 포함 — routine_id 유무로 구분 가능)
        memoRepository.findAllByPetIdInAndLoggedAtBetweenOrderByLoggedAtDesc(petIds, from, to)
                .forEach(m -> all.add(RecentRecordResponse.of(
                        "MEMO", m.getId(), m.getPetId(),
                        petNameMap.getOrDefault(m.getPetId(), ""),
                        petColorMap.get(m.getPetId()),
                        m.getLoggedAt(), "", m.getContent())));

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

        // 부가정보 없는 루틴 완료 (먹이 정보 없는 FEEDING, 메모 없는 CUSTOM)
        // — dtl 기록이 없어도 "[루틴제목] 완료"로 표시. dtl과 동시 저장된 로그는 제외
        String routineOnlySql = """
                SELECT l.id, l.pet_id, l.executed_at, r.title, r.routine_type
                FROM routine_log_dtl l
                JOIN routine_mst r ON r.id = l.routine_id
                JOIN pet_mst p ON p.id = l.pet_id
                WHERE p.user_id = ? AND p.deleted_at IS NULL
                  AND l.status = 'COMPLETED' AND l.deleted_at IS NULL
                  AND r.routine_type IN ('FEEDING', 'CUSTOM')
                  AND l.executed_at >= ? AND l.executed_at < ?
                  AND NOT EXISTS (
                      SELECT 1 FROM feeding_dtl f
                      WHERE r.routine_type = 'FEEDING'
                        AND f.routine_id = l.routine_id AND f.pet_id = l.pet_id
                        AND f.fed_at = l.executed_at AND f.deleted_at IS NULL)
                  AND NOT EXISTS (
                      SELECT 1 FROM memo_dtl m
                      WHERE r.routine_type = 'CUSTOM'
                        AND m.routine_id = l.routine_id AND m.pet_id = l.pet_id
                        AND m.logged_at = l.executed_at AND m.deleted_at IS NULL)
                """;
        jdbc.query(routineOnlySql,
                ps -> {
                    ps.setLong(1, userId);
                    ps.setTimestamp(2, java.sql.Timestamp.from(from));
                    ps.setTimestamp(3, java.sql.Timestamp.from(to));
                },
                rs -> {
                    Long petId = rs.getLong("pet_id");
                    String recordType = "FEEDING".equals(rs.getString("routine_type"))
                            ? "FEEDING" : "MEMO";
                    all.add(RecentRecordResponse.of(
                            recordType, rs.getLong("id"), petId,
                            petNameMap.getOrDefault(petId, ""),
                            petColorMap.get(petId),
                            rs.getTimestamp("executed_at").toInstant(),
                            "[" + rs.getString("title") + "] 완료", null));
                });

        all.sort(Comparator.comparing(RecentRecordResponse::createdAt).reversed());
        return all;
    }

    private static final Map<String, String> FOOD_TYPE_KO = Map.of(
            "CRICKET",      "귀뚜라미",
            "MEALWORM",     "밀웜",
            "FRUIT_FLY",    "초파리",
            "SUPERFOOD",    "슈퍼푸드",
            "PELLET",       "사료",
            "VEGETABLES",   "야채/과일",
            "FROZEN_VEGE",  "냉짱",
            "FROZEN_MOUSE", "마우스",
            "FROZEN_RAT",   "래트"
    );
    private static final Map<String, String> SUPPLEMENT_KO = Map.of(
            "CALCIUM",   "칼슘",
            "PROBIOTIC", "유산균",
            "VITAMIN",   "비타민",
            "OTHER",     "영양제"
    );

    private static String cleaningTypeKo(CleaningType type) {
        if (type == null) return "청소";
        return switch (type) {
            case FULL         -> "전체 청소";
            case PARTIAL      -> "부분 청소";
            case WATER_CHANGE -> "물 교체";
        };
    }

    private String buildFeedingSummary(FeedingDtl f) {
        String typeKo = f.getFoodType() != null
                ? FOOD_TYPE_KO.getOrDefault(f.getFoodType(), f.getFoodType())
                : "급여";
        StringBuilder sb = new StringBuilder(typeKo);
        if (f.getSizeLabel() != null && !f.getSizeLabel().isBlank()) {
            sb.append(" ").append(f.getSizeLabel());
        }
        if (f.getAmount() != null) {
            sb.append(" ").append(f.getAmount().stripTrailingZeros().toPlainString());
            sb.append(unitKo(f.getUnit()));
        }
        if (f.getSupplement() != null) {
            String supKo = SUPPLEMENT_KO.getOrDefault(f.getSupplement().name(), f.getSupplement().name());
            sb.append(" + ").append(supKo);
        }
        return sb.toString().trim();
    }

    /** 저장 단위 코드 → 표시 단위. PIECE=마리, ML=ml, 그 외(레거시 '마리' 등)는 그대로. */
    private static String unitKo(String unit) {
        if (unit == null) return "";
        return switch (unit) {
            case "PIECE" -> "마리";
            case "ML" -> "ml";
            default -> unit;
        };
    }

    private static String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() > max ? s.substring(0, max) + "…" : s;
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    private void verifyPetOwnership(Long userId, Long petId) {
        // 공유 개체 포함 — 사육자(OWNER/KEEPER)면 기록 작성·조회 가능
        petRepository.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!petKeeper.isKeeper(userId, petId)) {
            throw new BusinessException(ErrorCode.RECORD_ACCESS_DENIED);
        }
    }
}
