package io.bitpet.record.mating.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.record.mating.domain.MatingDtl;
import io.bitpet.record.mating.dto.MatingCreateRequest;
import io.bitpet.record.mating.dto.MatingListResponse;
import io.bitpet.record.mating.dto.MatingResponse;
import io.bitpet.record.mating.dto.MatingUpdateRequest;
import io.bitpet.record.mating.repository.MatingDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Year;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MatingService {

    private final MatingDtlRepository matingRepo;
    private final PetMstRepository petRepo;

    // -------------------------------------------------------------------------
    // 메이팅 등록
    // -------------------------------------------------------------------------

    @Transactional
    public MatingResponse createMating(Long petId, Long userId, MatingCreateRequest req) {
        PetMst malePet   = resolvePet(req.petIdMale());
        PetMst femalePet = resolvePet(req.petIdFemale());

        validateOwnership(userId, petId, req.petIdMale(), req.petIdFemale());
        validateGenders(malePet, femalePet);

        String seasonLabel = resolveSeasonLabel(req.seasonLabel(), req.triedAt().getYear());

        MatingDtl mating = matingRepo.save(MatingDtl.builder()
                .malePetId(req.petIdMale())
                .femalePetId(req.petIdFemale())
                .externalPartnerText(req.externalPartnerText())
                .triedAt(req.triedAt().toInstant())
                .durationMinutes(req.durationMinutes())
                .isSuccessful(req.isSuccessful())
                .seasonLabel(seasonLabel)
                .memo(req.memo())
                .build());

        return MatingResponse.of(mating, malePet, femalePet);
    }

    // -------------------------------------------------------------------------
    // 메이팅 목록
    // -------------------------------------------------------------------------

    public MatingListResponse getMatings(Long petId, Long userId,
                                         String seasonLabel, Boolean isSuccessful,
                                         Pageable pageable) {
        loadOwnedPet(userId, petId);
        Page<MatingDtl> page = matingRepo.findByPetIdWithFilters(petId, seasonLabel, isSuccessful, pageable);

        List<MatingResponse> items = page.getContent().stream()
                .map(m -> MatingResponse.of(m, resolvePet(m.getMalePetId()), resolvePet(m.getFemalePetId())))
                .toList();

        return new MatingListResponse(items, page.getTotalElements());
    }

    // -------------------------------------------------------------------------
    // 메이팅 단건
    // -------------------------------------------------------------------------

    public MatingResponse getMating(Long matingId, Long userId) {
        MatingDtl mating = loadAccessibleMating(matingId, userId);
        return MatingResponse.of(mating, resolvePet(mating.getMalePetId()), resolvePet(mating.getFemalePetId()));
    }

    // -------------------------------------------------------------------------
    // 메이팅 수정
    // -------------------------------------------------------------------------

    @Transactional
    public MatingResponse updateMating(Long matingId, Long userId, MatingUpdateRequest req) {
        MatingDtl mating = loadAccessibleMating(matingId, userId);

        PetMst malePet   = resolvePet(req.petIdMale());
        PetMst femalePet = resolvePet(req.petIdFemale());
        validateGenders(malePet, femalePet);

        String seasonLabel = resolveSeasonLabel(req.seasonLabel(), req.triedAt().getYear());

        mating.update(req.petIdMale(), req.petIdFemale(), req.externalPartnerText(),
                req.triedAt().toInstant(), req.durationMinutes(), req.isSuccessful(),
                seasonLabel, req.memo());

        return MatingResponse.of(mating, malePet, femalePet);
    }

    // -------------------------------------------------------------------------
    // 메이팅 삭제
    // -------------------------------------------------------------------------

    @Transactional
    public void deleteMating(Long matingId, Long userId) {
        MatingDtl mating = loadAccessibleMating(matingId, userId);
        mating.softDelete();
        // 연관 laying.mating_id는 DB ON DELETE SET NULL으로 자동 처리
    }

    // -------------------------------------------------------------------------
    // 내부 조회 helper (laying에서 재사용)
    // -------------------------------------------------------------------------

    public MatingDtl findById(Long matingId) {
        return matingRepo.findById(matingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.MATING_NOT_FOUND));
    }

    // -------------------------------------------------------------------------
    // private helpers
    // -------------------------------------------------------------------------

    private void validateOwnership(Long userId, Long contextPetId, Long malePetId, Long femalePetId) {
        // malePetId, femalePetId 중 최소 하나는 본인 소유
        if (malePetId == null && femalePetId == null) {
            throw new BusinessException(ErrorCode.MATING_OWNER_REQUIRED);
        }
        boolean maleOwned   = malePetId   != null && isOwnedBy(userId, malePetId);
        boolean femaleOwned = femalePetId != null && isOwnedBy(userId, femalePetId);

        if (!maleOwned && !femaleOwned) {
            throw new BusinessException(ErrorCode.MATING_OWNER_REQUIRED);
        }
        // contextPetId는 URL 경로의 petId — male 또는 female 중 하나와 일치해야 함
        if (contextPetId != null) {
            boolean matchesMale   = contextPetId.equals(malePetId);
            boolean matchesFemale = contextPetId.equals(femalePetId);
            if (!matchesMale && !matchesFemale) {
                throw new BusinessException(ErrorCode.MATING_OWNER_REQUIRED);
            }
        }
    }

    private void validateGenders(PetMst malePet, PetMst femalePet) {
        if (malePet != null && malePet.getGender() != PetGender.MALE) {
            throw new BusinessException(ErrorCode.MATING_PET_NOT_MALE);
        }
        if (femalePet != null && femalePet.getGender() != PetGender.FEMALE) {
            throw new BusinessException(ErrorCode.MATING_PET_NOT_FEMALE);
        }
    }

    private String resolveSeasonLabel(String given, int year) {
        if (given != null && !given.isBlank()) return given;
        return String.valueOf(year);
    }

    private PetMst resolvePet(Long petId) {
        if (petId == null) return null;
        return petRepo.findById(petId).orElse(null);
    }

    private boolean isOwnedBy(Long userId, Long petId) {
        return petRepo.findById(petId)
                .map(p -> p.getUserId().equals(userId))
                .orElse(false);
    }

    private PetMst loadOwnedPet(Long userId, Long petId) {
        PetMst pet = petRepo.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
        return pet;
    }

    private MatingDtl loadAccessibleMating(Long matingId, Long userId) {
        MatingDtl mating = matingRepo.findById(matingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.MATING_NOT_FOUND));
        // male 또는 female 중 본인 소유 확인
        boolean owned = (mating.getMalePetId()   != null && isOwnedBy(userId, mating.getMalePetId()))
                     || (mating.getFemalePetId() != null && isOwnedBy(userId, mating.getFemalePetId()));
        if (!owned) throw new BusinessException(ErrorCode.RECORD_ACCESS_DENIED);
        return mating;
    }
}
