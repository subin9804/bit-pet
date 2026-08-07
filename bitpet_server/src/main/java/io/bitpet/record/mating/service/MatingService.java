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
    private final io.bitpet.pet.service.PetKeeperService petKeeper;

    // -------------------------------------------------------------------------
    // 메이팅 등록
    // -------------------------------------------------------------------------

    @Transactional
    public MatingResponse createMating(Long petId, Long userId, MatingCreateRequest req) {
        PetMst malePet   = resolvePet(req.petIdMale());
        PetMst femalePet = resolvePet(req.petIdFemale());

        validateOwnership(userId, petId, req.petIdMale(), req.petIdFemale());
        validateGenders(malePet, femalePet);
        validateNotOrphaned(malePet, femalePet);

        String seasonLabel = resolveSeasonLabel(req.seasonLabel(), req.triedAt().getYear());

        MatingDtl mating = matingRepo.save(MatingDtl.builder()
                .malePetId(req.petIdMale())
                .femalePetId(req.petIdFemale())
                .createdByUserId(userId)
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
        // 이미 걸려 있던 고아는 그대로 둔다 — 차단하는 건 '신규' 참조뿐이다
        validateNotOrphaned(
                java.util.Objects.equals(mating.getMalePetId(),   req.petIdMale())   ? null : malePet,
                java.util.Objects.equals(mating.getFemalePetId(), req.petIdFemale()) ? null : femalePet);

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
        matingRepo.delete(mating); // hard delete
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

    /**
     * 주인이 탈퇴해 익명화된 개체는 메이팅 상대로 새로 지정할 수 없다(고아 신규 참조 차단).
     * 클라이언트 필터링만으로는 부족해 API 레벨에서 막는다.
     */
    private void validateNotOrphaned(PetMst... pets) {
        for (PetMst pet : pets) {
            if (pet != null && pet.isOrphaned()) {
                throw new BusinessException(ErrorCode.PET_ORPHANED);
            }
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
        // 공유 개체 포함 — 사육자(OWNER/KEEPER)면 본인 개체로 취급
        return petKeeper.isKeeper(userId, petId);
    }

    private PetMst loadOwnedPet(Long userId, Long petId) {
        // 공유 개체 포함 — 사육자(OWNER/KEEPER)면 기록 작성·조회 가능
        return petKeeper.assertKeeper(userId, petId);
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
