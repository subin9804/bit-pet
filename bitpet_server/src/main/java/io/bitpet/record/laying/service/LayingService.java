package io.bitpet.record.laying.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.domain.PetRelationRls;
import io.bitpet.pet.domain.RelationType;
import io.bitpet.pet.domain.SpeciesCd;
import io.bitpet.pet.domain.MorphCd;
import io.bitpet.pet.repository.MorphCdRepository;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.repository.PetRelationRlsRepository;
import io.bitpet.pet.repository.SpeciesCdRepository;
import io.bitpet.pet.service.SerialNumberGenerator;
import io.bitpet.record.laying.domain.HatchStatus;
import io.bitpet.record.laying.domain.LayingDtl;
import io.bitpet.record.laying.domain.LayingHatchDtl;
import io.bitpet.record.laying.dto.HatchCreateRequest;
import io.bitpet.record.laying.dto.HatchResponse;
import io.bitpet.record.laying.dto.HatchUpdateRequest;
import io.bitpet.record.laying.dto.LayingCreateRequest;
import io.bitpet.record.laying.dto.LayingResponse;
import io.bitpet.record.laying.dto.LayingUpdateRequest;
import io.bitpet.record.laying.dto.RegisterPetRequest;
import io.bitpet.record.laying.repository.LayingDtlRepository;
import io.bitpet.record.laying.repository.LayingHatchDtlRepository;
import io.bitpet.record.mating.domain.MatingDtl;
import io.bitpet.record.mating.repository.MatingDtlRepository;
import io.bitpet.pet.dto.PetResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class LayingService {

    private final LayingDtlRepository layingRepo;
    private final LayingHatchDtlRepository hatchRepo;
    private final MatingDtlRepository matingRepo;
    private final PetMstRepository petRepo;
    private final PetRelationRlsRepository relationRepo;
    private final SpeciesCdRepository speciesRepo;
    private final MorphCdRepository morphRepo;
    private final SerialNumberGenerator serialNumberGenerator;

    // -------------------------------------------------------------------------
    // 산란 등록
    // -------------------------------------------------------------------------

    @Transactional
    public LayingResponse createLaying(Long petId, Long userId, LayingCreateRequest req) {
        PetMst pet = loadOwnedPet(userId, petId);
        validateFemale(pet);
        validateEggCounts(req.eggCountTotal(), req.eggCountFertile());

        if (req.matingId() != null) {
            validateMatingFemale(req.matingId(), petId);
        }

        LayingDtl laying = layingRepo.save(LayingDtl.builder()
                .petId(petId)
                .matingId(req.matingId())
                .laidAt(req.laidAt().toInstant())
                .eggCountTotal(req.eggCountTotal())
                .eggCountFertile(req.eggCountFertile())
                .incubationTemp(req.incubationTemp())
                .incubationHumidity(req.incubationHumidity())
                .memo(req.memo())
                .build());

        return LayingResponse.of(laying, List.of());
    }

    // -------------------------------------------------------------------------
    // 산란 목록
    // -------------------------------------------------------------------------

    public Page<LayingResponse> getLayings(Long petId, Long userId,
                                            Long matingId,
                                            LocalDate from, LocalDate to,
                                            Pageable pageable) {
        loadOwnedPet(userId, petId);
        Instant fromInst = from != null ? from.atStartOfDay().toInstant(ZoneOffset.UTC) : null;
        Instant toInst   = to   != null ? to.atTime(23, 59, 59).toInstant(ZoneOffset.UTC) : null;

        return layingRepo.findByPetIdWithFilters(petId, matingId, fromInst, toInst, pageable)
                .map(l -> LayingResponse.of(l, buildHatches(l.getId())));
    }

    // -------------------------------------------------------------------------
    // 산란 단건
    // -------------------------------------------------------------------------

    public LayingResponse getLaying(Long layingId, Long userId) {
        LayingDtl laying = loadAccessibleLaying(layingId, userId);
        return LayingResponse.of(laying, buildHatches(layingId));
    }

    // -------------------------------------------------------------------------
    // 산란 수정
    // -------------------------------------------------------------------------

    @Transactional
    public LayingResponse updateLaying(Long layingId, Long userId, LayingUpdateRequest req) {
        LayingDtl laying = loadAccessibleLaying(layingId, userId);
        validateEggCounts(req.eggCountTotal(), req.eggCountFertile());

        if (req.matingId() != null) {
            validateMatingFemale(req.matingId(), laying.getPetId());
        }

        laying.update(req.matingId(), req.laidAt().toInstant(), req.eggCountTotal(),
                req.eggCountFertile(), req.incubationTemp(), req.incubationHumidity(), req.memo());

        return LayingResponse.of(laying, buildHatches(layingId));
    }

    // -------------------------------------------------------------------------
    // 산란 삭제
    // -------------------------------------------------------------------------

    @Transactional
    public void deleteLaying(Long layingId, Long userId) {
        LayingDtl laying = loadAccessibleLaying(layingId, userId);
        // hatch는 DB CASCADE — soft delete
        hatchRepo.findAllByLayingIdOrderByCreatedAtAsc(layingId)
                .forEach(LayingHatchDtl::softDelete);
        laying.softDelete();
    }

    // -------------------------------------------------------------------------
    // 해칭 추가
    // -------------------------------------------------------------------------

    @Transactional
    public HatchResponse createHatch(Long layingId, Long userId, HatchCreateRequest req) {
        LayingDtl laying = loadAccessibleLaying(layingId, userId);

        if (req.status() == HatchStatus.HATCHED && req.hatchedAt() == null) {
            throw new BusinessException(ErrorCode.HATCH_INVALID_STATUS_TRANSITION);
        }

        LayingHatchDtl hatch = hatchRepo.save(LayingHatchDtl.builder()
                .layingId(layingId)
                .status(req.status())
                .hatchedAt(req.hatchedAt() != null ? req.hatchedAt().toInstant() : null)
                .memo(req.memo())
                .build());

        return HatchResponse.of(hatch, null);
    }

    // -------------------------------------------------------------------------
    // 해칭 수정
    // -------------------------------------------------------------------------

    @Transactional
    public HatchResponse updateHatch(Long layingId, Long hatchId, Long userId, HatchUpdateRequest req) {
        loadAccessibleLaying(layingId, userId);
        LayingHatchDtl hatch = loadHatch(hatchId, layingId);

        Instant hatchedAt = req.hatchedAt() != null ? req.hatchedAt().toInstant() : null;

        if (req.status() == HatchStatus.HATCHED && hatchedAt == null) {
            throw new BusinessException(ErrorCode.HATCH_INVALID_STATUS_TRANSITION);
        }

        hatch.update(req.status(), hatchedAt, req.hatchedPetId(), req.memo());

        // hatchedPetId 설정 시 자동 lineage 생성
        if (req.hatchedPetId() != null) {
            createLineage(layingId, req.hatchedPetId());
        }

        PetMst hatchedPet = req.hatchedPetId() != null ? petRepo.findById(req.hatchedPetId()).orElse(null) : null;
        return HatchResponse.of(hatch, hatchedPet);
    }

    // -------------------------------------------------------------------------
    // 해칭 삭제
    // -------------------------------------------------------------------------

    @Transactional
    public void deleteHatch(Long layingId, Long hatchId, Long userId) {
        loadAccessibleLaying(layingId, userId);
        LayingHatchDtl hatch = loadHatch(hatchId, layingId);
        hatch.softDelete();
    }

    // -------------------------------------------------------------------------
    // 편의 API: 해칭 → 신규 개체 등록 + lineage 자동 연결
    // -------------------------------------------------------------------------

    @Transactional
    public PetResponse registerPet(Long layingId, Long hatchId, Long userId, RegisterPetRequest req) {
        LayingDtl laying = loadAccessibleLaying(layingId, userId);
        LayingHatchDtl hatch = loadHatch(hatchId, layingId);

        SpeciesCd species = req.speciesId() != null
                ? speciesRepo.findById(req.speciesId())
                        .orElseThrow(() -> new BusinessException(ErrorCode.SPECIES_NOT_FOUND))
                : null;
        MorphCd morph = req.morphId() != null
                ? morphRepo.findById(req.morphId())
                        .orElseThrow(() -> new BusinessException(ErrorCode.MORPH_NOT_FOUND))
                : null;

        String serial = serialNumberGenerator.generate();
        PetMst newPet = petRepo.save(PetMst.builder()
                .serialNo(serial)
                .userId(userId)
                .species(species)
                .morph(morph)
                .name(req.name())
                .gender(req.gender())
                .hatchingDate(req.birthDate())
                .description(req.memo())
                .build());

        hatch.linkPet(newPet.getId());
        createLineage(layingId, newPet.getId());

        return PetResponse.from(newPet);
    }

    // -------------------------------------------------------------------------
    // private helpers
    // -------------------------------------------------------------------------

    private void createLineage(Long layingId, Long childPetId) {
        LayingDtl laying = layingRepo.findById(layingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.LAYING_NOT_FOUND));
        PetMst childPet = petRepo.findById(childPetId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));

        // 모(母) 연결
        PetMst motherPet = petRepo.findById(laying.getPetId()).orElse(null);
        if (motherPet != null
                && !relationRepo.existsByParentPetIdAndChildPetIdAndRelationType(
                        laying.getPetId(), childPetId, RelationType.MOTHER)) {
            relationRepo.save(PetRelationRls.builder()
                    .parentPet(motherPet)
                    .childPet(childPet)
                    .relationType(RelationType.MOTHER)
                    .build());
        }

        // 부(父) 연결 — mating 있을 때만
        if (laying.getMatingId() != null) {
            matingRepo.findById(laying.getMatingId()).ifPresent(mating -> {
                if (mating.getMalePetId() != null) {
                    PetMst fatherPet = petRepo.findById(mating.getMalePetId()).orElse(null);
                    if (fatherPet != null
                            && !relationRepo.existsByParentPetIdAndChildPetIdAndRelationType(
                                    mating.getMalePetId(), childPetId, RelationType.FATHER)) {
                        relationRepo.save(PetRelationRls.builder()
                                .parentPet(fatherPet)
                                .childPet(childPet)
                                .relationType(RelationType.FATHER)
                                .build());
                    }
                }
            });
        }
    }

    private List<HatchResponse> buildHatches(Long layingId) {
        return hatchRepo.findAllByLayingIdOrderByCreatedAtAsc(layingId).stream()
                .map(h -> {
                    PetMst p = h.getHatchedPetId() != null
                            ? petRepo.findById(h.getHatchedPetId()).orElse(null) : null;
                    return HatchResponse.of(h, p);
                })
                .toList();
    }

    private void validateFemale(PetMst pet) {
        if (pet.getGender() != PetGender.FEMALE) {
            throw new BusinessException(ErrorCode.LAYING_PET_NOT_FEMALE);
        }
    }

    private void validateEggCounts(int total, Integer fertile) {
        if (fertile != null && fertile > total) {
            throw new BusinessException(ErrorCode.LAYING_FERTILE_EXCEEDS_TOTAL);
        }
    }

    private void validateMatingFemale(Long matingId, Long petId) {
        MatingDtl mating = matingRepo.findById(matingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.MATING_NOT_FOUND));
        if (mating.getFemalePetId() != null && !mating.getFemalePetId().equals(petId)) {
            throw new BusinessException(ErrorCode.LAYING_MATING_MISMATCH);
        }
    }

    private PetMst loadOwnedPet(Long userId, Long petId) {
        PetMst pet = petRepo.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
        return pet;
    }

    private LayingDtl loadAccessibleLaying(Long layingId, Long userId) {
        LayingDtl laying = layingRepo.findById(layingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.LAYING_NOT_FOUND));
        loadOwnedPet(userId, laying.getPetId());
        return laying;
    }

    private LayingHatchDtl loadHatch(Long hatchId, Long layingId) {
        return hatchRepo.findByIdAndLayingId(hatchId, layingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.HATCH_NOT_FOUND));
    }
}
