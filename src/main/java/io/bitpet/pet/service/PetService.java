package io.bitpet.pet.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.MatingRls;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.domain.PetRelationRls;
import io.bitpet.pet.domain.RelationType;
import io.bitpet.pet.domain.SpeciesCd;
import io.bitpet.pet.dto.GenealogyResponse;
import io.bitpet.pet.dto.MatingRequest;
import io.bitpet.pet.dto.MatingResponse;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetRelationRequest;
import io.bitpet.pet.dto.PetRelationResponse;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.dto.PetUpdateRequest;
import io.bitpet.pet.repository.MatingRlsRepository;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.repository.PetRelationRlsRepository;
import io.bitpet.pet.repository.SpeciesCdRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PetService {

    private final PetMstRepository petRepository;
    private final SpeciesCdRepository speciesRepository;
    private final PetRelationRlsRepository relationRepository;
    private final MatingRlsRepository matingRepository;
    private final SerialNumberGenerator serialNumberGenerator;

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
                .environmentMemo(req.environmentMemo())
                .breedingDate(req.breedingDate())
                .hatchingDate(req.hatchingDate())
                .adoptionDate(req.adoptionDate())
                .build();
        return PetResponse.from(petRepository.save(pet));
    }

    public PetResponse get(Long userId, Long petId) {
        return PetResponse.from(loadOwnedPet(userId, petId));
    }

    public List<PetResponse> listByOwner(Long userId) {
        return petRepository.findAllByUserId(userId).stream()
                .map(PetResponse::from)
                .toList();
    }

    public List<PetResponse> search(Long userId, Long speciesId, PetGender gender, String name) {
        return petRepository.search(userId, speciesId, gender, name).stream()
                .map(PetResponse::from)
                .toList();
    }

    @Transactional
    public PetResponse update(Long userId, Long petId, PetUpdateRequest req) {
        PetMst pet = loadOwnedPet(userId, petId);
        SpeciesCd species = req.speciesId() != null
                ? speciesRepository.findById(req.speciesId())
                        .orElseThrow(() -> new BusinessException(ErrorCode.SPECIES_NOT_FOUND))
                : null;
        pet.updateProfile(req.name(), species, req.gender(), req.colorCode(),
                req.environmentMemo(), req.breedingDate(), req.hatchingDate(), req.adoptionDate());
        return PetResponse.from(pet);
    }

    @Transactional
    public void delete(Long userId, Long petId) {
        PetMst pet = loadOwnedPet(userId, petId);
        pet.softDelete();
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
    // D3: 메이팅 기록
    // -------------------------------------------------------------------------

    @Transactional
    public MatingResponse addMating(Long userId, MatingRequest req) {
        PetMst male   = loadOwnedPet(userId, req.malePetId());
        PetMst female = loadOwnedPet(userId, req.femalePetId());
        MatingRls mating = MatingRls.builder()
                .malePet(male)
                .femalePet(female)
                .matingDate(req.matingDate())
                .memo(req.memo())
                .build();
        return MatingResponse.from(matingRepository.save(mating));
    }

    public List<MatingResponse> listMatings(Long userId, Long petId) {
        loadOwnedPet(userId, petId);
        return matingRepository.findAllByPetId(petId).stream()
                .map(MatingResponse::from)
                .toList();
    }

    @Transactional
    public void deleteMating(Long userId, Long matingId) {
        MatingRls mating = matingRepository.findById(matingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.MATING_NOT_FOUND));
        loadOwnedPet(userId, mating.getMalePet().getId());
        matingRepository.delete(mating);
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
}
