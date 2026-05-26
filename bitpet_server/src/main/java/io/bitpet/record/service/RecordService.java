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
import io.bitpet.record.memo.domain.MemoDtl;
import io.bitpet.record.memo.repository.MemoDtlRepository;
import io.bitpet.record.repository.CleaningDtlRepository;
import io.bitpet.record.repository.FeedingDtlRepository;
import io.bitpet.record.repository.WeightDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
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
                .feedResponse(req.feedResponse())
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
        feeding.update(req.foodType(), req.amount(), req.unit(), req.feedResponse(), req.fedAt(), req.memo());
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
        Map<Long, String> petNameMap = pets.stream()
                .collect(Collectors.toMap(PetMst::getId, PetMst::getName));

        PageRequest page = PageRequest.of(0, limit);
        List<RecentRecordResponse> all = new ArrayList<>();

        feedingRepository.findAllByPetIdInOrderByFedAtDesc(petIds, page).forEach(f ->
                all.add(new RecentRecordResponse("FEEDING", f.getId(), f.getPetId(),
                        petNameMap.getOrDefault(f.getPetId(), ""),
                        f.getFedAt(), buildFeedingSummary(f))));

        weightRepository.findAllByPetIdInOrderByMeasuredAtDesc(petIds, page).forEach(w ->
                all.add(new RecentRecordResponse("WEIGHT", w.getId(), w.getPetId(),
                        petNameMap.getOrDefault(w.getPetId(), ""),
                        w.getMeasuredAt(), w.getWeightG() + "g")));

        cleaningRepository.findAllByPetIdInOrderByCleanedAtDesc(petIds, page).forEach(c ->
                all.add(new RecentRecordResponse("CLEANING", c.getId(), c.getPetId(),
                        petNameMap.getOrDefault(c.getPetId(), ""),
                        c.getCleanedAt(), c.getCleaningType() != null ? c.getCleaningType().name() : "")));

        // v5: health_memo → memo
        memoRepository.findAllByPetIdInOrderByLoggedAtDesc(petIds, page).forEach(m ->
                all.add(new RecentRecordResponse("MEMO", m.getId(), m.getPetId(),
                        petNameMap.getOrDefault(m.getPetId(), ""),
                        m.getLoggedAt(),
                        m.getContent() != null && m.getContent().length() > 50
                                ? m.getContent().substring(0, 50) + "…"
                                : m.getContent())));

        all.sort(Comparator.comparing(RecentRecordResponse::occurredAt).reversed());
        return all.subList(0, Math.min(limit, all.size()));
    }

    private String buildFeedingSummary(FeedingDtl f) {
        StringBuilder sb = new StringBuilder(f.getFoodType() != null ? f.getFoodType() : "");
        if (f.getAmount() != null) {
            sb.append(" ").append(f.getAmount().stripTrailingZeros().toPlainString());
            if (f.getUnit() != null) sb.append(f.getUnit());
        }
        return sb.toString().trim();
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
