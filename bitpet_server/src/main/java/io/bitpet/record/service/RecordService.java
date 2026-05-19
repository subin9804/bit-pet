package io.bitpet.record.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.record.domain.CleaningDtl;
import io.bitpet.record.domain.FeedingDtl;
import io.bitpet.record.domain.HealthMemoDtl;
import io.bitpet.record.domain.WeightDtl;
import io.bitpet.record.dto.CleaningCreateRequest;
import io.bitpet.record.dto.CleaningResponse;
import io.bitpet.record.dto.CleaningUpdateRequest;
import io.bitpet.record.dto.FeedingCreateRequest;
import io.bitpet.record.dto.FeedingResponse;
import io.bitpet.record.dto.FeedingUpdateRequest;
import io.bitpet.record.dto.HealthLogCreateRequest;
import io.bitpet.record.dto.HealthLogResponse;
import io.bitpet.record.dto.HealthLogUpdateRequest;
import io.bitpet.record.dto.WeightCreateRequest;
import io.bitpet.record.dto.WeightResponse;
import io.bitpet.record.repository.CleaningDtlRepository;
import io.bitpet.record.repository.FeedingDtlRepository;
import io.bitpet.record.repository.HealthMemoDtlRepository;
import io.bitpet.record.repository.WeightDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RecordService {

    private final PetMstRepository petRepository;
    private final WeightDtlRepository weightRepository;
    private final FeedingDtlRepository feedingRepository;
    private final CleaningDtlRepository cleaningRepository;
    private final HealthMemoDtlRepository healthLogRepository;

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
        feeding.update(req.foodType(), req.amount(), req.unit(), req.fedAt(), req.memo());
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
    // Health Log (health_memo_dtl)
    // -------------------------------------------------------------------------

    public List<HealthLogResponse> listHealthLogs(Long userId, Long petId) {
        verifyPetOwnership(userId, petId);
        return healthLogRepository.findAllByPetIdOrderByRecordedAtDesc(petId)
                .stream().map(HealthLogResponse::from).toList();
    }

    @Transactional
    public HealthLogResponse addHealthLog(Long userId, Long petId, HealthLogCreateRequest req) {
        verifyPetOwnership(userId, petId);
        HealthMemoDtl saved = healthLogRepository.save(HealthMemoDtl.builder()
                .petId(petId)
                .symptom(req.symptom())
                .treatment(req.treatment())
                .memo(req.memo())
                .recordedAt(req.recordedAt())
                .build());
        return HealthLogResponse.from(saved);
    }

    @Transactional
    public HealthLogResponse updateHealthLog(Long userId, Long logId, HealthLogUpdateRequest req) {
        HealthMemoDtl log = healthLogRepository.findById(logId)
                .orElseThrow(() -> new BusinessException(ErrorCode.HEALTH_LOG_NOT_FOUND));
        verifyPetOwnership(userId, log.getPetId());
        log.update(req.symptom(), req.treatment(), req.memo(), req.recordedAt());
        return HealthLogResponse.from(log);
    }

    @Transactional
    public void deleteHealthLog(Long userId, Long logId) {
        HealthMemoDtl log = healthLogRepository.findById(logId)
                .orElseThrow(() -> new BusinessException(ErrorCode.HEALTH_LOG_NOT_FOUND));
        verifyPetOwnership(userId, log.getPetId());
        log.softDelete();
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
