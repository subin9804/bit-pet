package io.bitpet.pet.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.group.repository.BreedingGroupUserRlsRepository;
import io.bitpet.pet.domain.MorphCd;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMorphRls;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.domain.PetRelationRls;
import io.bitpet.pet.domain.SpeciesCd;
import io.bitpet.pet.dto.GenealogyResponse;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetRelationRequest;
import io.bitpet.pet.dto.PetRelationResponse;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.dto.PetUpdateRequest;
import io.bitpet.pet.repository.MorphCdRepository;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.repository.PetRelationRlsRepository;
import io.bitpet.pet.repository.SpeciesCdRepository;
import io.bitpet.record.domain.WeightDtl;
import io.bitpet.record.domain.WeightSource;
import io.bitpet.record.repository.WeightDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PetService {

    private final PetMstRepository petRepository;
    private final SpeciesCdRepository speciesRepository;
    private final MorphCdRepository morphRepository;
    private final PetRelationRlsRepository relationRepository;
    private final SerialNumberGenerator serialNumberGenerator;
    private final BreedingGroupUserRlsRepository groupMembershipRepository;
    private final WeightDtlRepository weightRepository;

    // -------------------------------------------------------------------------
    // D2: Pet CRUD
    // -------------------------------------------------------------------------

    @Transactional
    public PetResponse create(Long userId, PetCreateRequest req) {
        SpeciesCd species = req.speciesId() != null
                ? speciesRepository.findById(req.speciesId())
                        .orElseThrow(() -> new BusinessException(ErrorCode.SPECIES_NOT_FOUND))
                : null;

        String serial = serialNumberGenerator.generate();
        PetMst pet = PetMst.builder()
                .serialNo(serial)
                .userId(userId)
                .species(species)
                .name(req.name())
                .gender(req.gender())
                .colorCode(req.colorCode())
                .description(req.description())
                .breedingDate(req.breedingDate())
                .hatchingDate(req.hatchingDate())
                .hatchingDatePrecision(req.hatchingDatePrecision())
                .hatchingDateApproximate(req.hatchingDateApproximate())
                .adoptionDate(req.adoptionDate())
                .build();
        groupMembershipRepository.findByIdUserId(userId)
                .ifPresent(membership -> pet.assignGroup(membership.getId().getGroupId()));
        petRepository.save(pet);

        attachMorphs(pet, req.morphIds(), species);

        if (req.currentWeightG() != null && req.currentWeightG() > 0) {
            weightRepository.save(WeightDtl.builder()
                    .petId(pet.getId())
                    .weightG(BigDecimal.valueOf(req.currentWeightG()))
                    .measuredAt(Instant.now())
                    .source(WeightSource.MANUAL)
                    .build());
        }

        return PetResponse.from(pet);
    }

    public PetResponse get(Long userId, Long petId) {
        PetMst pet = loadOwnedPet(userId, petId);
        Double latestWeight = weightRepository.findAllByPetIdOrderByMeasuredAtDesc(pet.getId())
                .stream().findFirst()
                .map(w -> w.getWeightG().doubleValue())
                .orElse(null);
        List<PetRelationRls> parentRelations = relationRepository.findAllByChildPetId(petId);
        return PetResponse.from(pet, latestWeight, parentRelations);
    }

    public List<PetResponse> listByOwner(Long userId) {
        return petRepository.findAllByUserId(userId).stream()
                // 폐사(이별) 개체는 목록 마지막으로 (stable sort — 기존 순서 유지)
                .sorted(java.util.Comparator.comparing(p -> p.getDeceasedAt() != null))
                .map(pet -> {
                    Double latestWeight = weightRepository.findAllByPetIdOrderByMeasuredAtDesc(pet.getId())
                            .stream().findFirst()
                            .map(w -> w.getWeightG().doubleValue())
                            .orElse(null);
                    return PetResponse.from(pet, latestWeight);
                })
                .toList();
    }

    public List<PetResponse> search(Long userId, Long speciesId, PetGender gender, String name) {
        return petRepository.search(userId, speciesId, gender, name).stream()
                .map(PetResponse::from)
                .toList();
    }

    /** 일련번호로 공개 개체 조회 — 검색 허용(private_yn='N')인 개체만 반환 */
    public PetResponse findBySerial(String serialNo) {
        PetMst pet = petRepository.findBySerialNo(serialNo.toUpperCase())
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!"N".equals(pet.getPrivateYn())) {
            throw new BusinessException(ErrorCode.PET_NOT_FOUND); // 비공개는 404로 동일 처리
        }
        return PetResponse.from(pet);
    }

    @Transactional
    public PetResponse update(Long userId, Long petId, PetUpdateRequest req) {
        PetMst pet = loadOwnedPet(userId, petId);
        SpeciesCd species = req.speciesId() != null
                ? speciesRepository.findById(req.speciesId())
                        .orElseThrow(() -> new BusinessException(ErrorCode.SPECIES_NOT_FOUND))
                : null;
        SpeciesCd effectiveSpecies = species != null ? species : pet.getSpecies();
        pet.updateProfile(req.name(), species, req.gender(), req.colorCode(),
                req.description(), req.breedingDate(), req.hatchingDate(),
                req.hatchingDatePrecision(), req.hatchingDateApproximate(), req.adoptionDate());
        pet.updatePrivacy(req.privateYn());

        List<Long> morphIds = req.morphIds();
        if (morphIds == null && req.morphId() != null) {
            morphIds = List.of(req.morphId());
        }
        if (morphIds != null) {
            pet.getMorphs().clear();
            attachMorphs(pet, morphIds, effectiveSpecies);
        }
        return PetResponse.from(pet);
    }

    @Transactional
    public void delete(Long userId, Long petId) {
        PetMst pet = loadOwnedPet(userId, petId);
        pet.softDelete();
    }

    /** 이별하기 — 폐사 처리 (기록은 그대로 보존) */
    @Transactional
    public PetResponse markDeceased(Long userId, Long petId, java.time.LocalDate deceasedAt) {
        PetMst pet = loadOwnedPet(userId, petId);
        pet.markDeceased(deceasedAt);
        return PetResponse.from(pet);
    }

    /** 이별 취소 — 폐사 표시 해제 */
    @Transactional
    public PetResponse revertDeceased(Long userId, Long petId) {
        PetMst pet = loadOwnedPet(userId, petId);
        pet.revertDeceased();
        return PetResponse.from(pet);
    }

    // -------------------------------------------------------------------------
    // D3: 부모-자식 관계
    // -------------------------------------------------------------------------

    @Transactional
    public PetRelationResponse addRelation(Long userId, PetRelationRequest req) {
        PetMst parent = loadOwnedPet(userId, req.parentPetId());
        PetMst child  = loadOwnedPet(userId, req.childPetId());

        if (relationRepository.existsByParentPetIdAndChildPetIdAndRelationType(
                req.parentPetId(), req.childPetId(), req.relationType())) {
            throw new BusinessException(ErrorCode.PET_RELATION_DUPLICATE);
        }
        PetRelationRls relation = PetRelationRls.builder()
                .parentPet(parent)
                .childPet(child)
                .relationType(req.relationType())
                .build();
        return PetRelationResponse.from(relationRepository.save(relation));
    }

    public List<PetRelationResponse> listRelations(Long userId, Long petId) {
        loadOwnedPet(userId, petId);
        List<PetRelationRls> asChild  = relationRepository.findAllByChildPetId(petId);
        List<PetRelationRls> asParent = relationRepository.findAllByParentPetId(petId);
        return java.util.stream.Stream.concat(asChild.stream(), asParent.stream())
                .map(PetRelationResponse::from)
                .toList();
    }

    @Transactional
    public void deleteRelation(Long userId, Long relationId) {
        PetRelationRls relation = relationRepository.findById(relationId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_RELATION_NOT_FOUND));
        loadOwnedPet(userId, relation.getParentPet().getId());
        relationRepository.delete(relation);
    }

    public GenealogyResponse getGenealogy(Long userId, Long petId) {
        PetMst pet = loadOwnedPet(userId, petId);
        List<PetMst> parents  = relationRepository.findParentsOf(petId);
        List<PetMst> children = relationRepository.findChildrenOf(petId);
        return new GenealogyResponse(
                PetResponse.from(pet),
                parents.stream().map(PetResponse::from).toList(),
                children.stream().map(PetResponse::from).toList()
        );
    }

    // -------------------------------------------------------------------------
    // 내부 헬퍼
    // -------------------------------------------------------------------------

    private PetMst loadOwnedPet(Long userId, Long petId) {
        PetMst pet = petRepository.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
        return pet;
    }

    private void attachMorphs(PetMst pet, List<Long> morphIds, SpeciesCd species) {
        if (morphIds == null || morphIds.isEmpty()) return;
        for (Long morphId : morphIds) {
            MorphCd morph = morphRepository.findById(morphId)
                    .orElseThrow(() -> new BusinessException(ErrorCode.MORPH_NOT_FOUND));
            if (species != null && !morph.getSpeciesId().equals(species.getId())) {
                throw new BusinessException(ErrorCode.MORPH_SPECIES_MISMATCH);
            }
            pet.getMorphs().add(PetMorphRls.of(pet, morph));
        }
    }
}
