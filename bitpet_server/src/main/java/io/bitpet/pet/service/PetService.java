package io.bitpet.pet.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.MorphCd;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMorphRls;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.domain.PetRelationRls;
import io.bitpet.pet.domain.SpeciesCd;
import io.bitpet.pet.dto.GenealogyResponse;
import io.bitpet.pet.dto.PetBulkDeleteResponse;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetRelationRequest;
import io.bitpet.pet.dto.PetRelationResponse;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.dto.PetUpdateRequest;
import io.bitpet.pet.repository.MorphCdRepository;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.repository.PetRelationRlsRepository;
import io.bitpet.pet.repository.SpeciesCdRepository;
import io.bitpet.photo.domain.EntityType;
import io.bitpet.photo.domain.PhotoDtl;
import io.bitpet.photo.repository.PhotoDtlRepository;
import io.bitpet.record.domain.WeightDtl;
import io.bitpet.record.domain.WeightSource;
import io.bitpet.record.repository.WeightDtlRepository;
import io.bitpet.storage.S3Service;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PetService {

    private final PetMstRepository petRepository;
    private final SpeciesCdRepository speciesRepository;
    private final MorphCdRepository morphRepository;
    private final PetRelationRlsRepository relationRepository;
    private final SerialNumberGenerator serialNumberGenerator;
    private final PetKeeperService petKeeper;
    private final io.bitpet.routine.service.RoutineMaintenanceService routineMaintenance;
    private final WeightDtlRepository weightRepository;
    private final PhotoDtlRepository photoRepository;
    private final S3Service s3Service;

    /** 대표 사진 id → 표시용 presigned URL (없으면 null) */
    private String resolveProfileImageUrl(PetMst pet) {
        if (pet.getProfilePhotoId() == null) return null;
        return photoRepository.findById(pet.getProfilePhotoId())
                .map(p -> s3Service.resolveUrl(p.getS3Key()))
                .orElse(null);
    }

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
        petRepository.save(pet);
        petKeeper.registerOwner(pet.getId(), userId);

        attachMorphs(pet, req.morphIds(), species);

        if (req.currentWeightG() != null && req.currentWeightG() > 0) {
            weightRepository.save(WeightDtl.builder()
                    .petId(pet.getId())
                    .createdByUserId(userId)
                    .weightG(BigDecimal.valueOf(req.currentWeightG()))
                    .measuredAt(Instant.now())
                    .source(WeightSource.MANUAL)
                    .build());
        }

        return PetResponse.from(pet);
    }

    public PetResponse get(Long userId, Long petId) {
        PetMst pet = petKeeper.assertKeeper(userId, petId);
        Double latestWeight = weightRepository.findAllByPetIdOrderByMeasuredAtDesc(pet.getId())
                .stream().findFirst()
                .map(w -> w.getWeightG().doubleValue())
                .orElse(null);
        List<PetRelationRls> parentRelations = relationRepository.findAllByChildPetId(petId);
        return PetResponse.from(pet, latestWeight, parentRelations,
                resolveProfileImageUrl(pet), petKeeper.isOwner(userId, petId));
    }

    /** 내가 사육하는 개체 목록 (소유 + 공유받은 개체) */
    public List<PetResponse> listByOwner(Long userId) {
        List<Long> petIds = petKeeper.keptPetIds(userId);
        if (petIds.isEmpty()) return List.of();
        // 목록에는 공유받은 개체도 섞여 있다 — 개체마다 소유자를 다시 묻지 않도록 한 번에 받아둔다
        Set<Long> ownedIds = petKeeper.ownedPetIds(userId);
        return petRepository.findAllById(petIds).stream()
                // 폐사(이별) 개체는 목록 마지막으로 (stable sort — 기존 순서 유지)
                .sorted(java.util.Comparator.comparing(p -> p.getDeceasedAt() != null))
                .map(pet -> {
                    Double latestWeight = weightRepository.findAllByPetIdOrderByMeasuredAtDesc(pet.getId())
                            .stream().findFirst()
                            .map(w -> w.getWeightG().doubleValue())
                            .orElse(null);
                    return PetResponse.from(pet, latestWeight, List.of(),
                            resolveProfileImageUrl(pet), ownedIds.contains(pet.getId()));
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

    /**
     * 개체 프로필 수정 — <b>공유받은 사육자(KEEPER)도 가능</b>.
     * 공동 양육자는 이미 체중·급여 같은 기록을 남기는 사람이라,
     * 이름·모프·해칭일을 고치는 것까지 소유자에게만 열어 둘 이유가 없다.
     * 반면 삭제·이별·공유·입분양은 개체의 존재나 소유권 자체를 바꾸므로 OWNER 전용으로 남긴다.
     */
    @Transactional
    public PetResponse update(Long userId, Long petId, PetUpdateRequest req) {
        PetMst pet = petKeeper.assertKeeper(userId, petId);
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
            syncMorphs(pet, morphIds, effectiveSpecies);
        }
        return PetResponse.from(pet, null, List.of(), null, petKeeper.isOwner(userId, petId));
    }

    /**
     * 갤러리 사진 중 하나를 대표(프로필) 사진으로 지정 — KEEPER도 가능.
     * 사진 등록 자체가 이미 사육자에게 열려 있어(PhotoService), 그중 한 장을 고르는 것만 막을 이유가 없다.
     */
    @Transactional
    public PetResponse setProfilePhoto(Long userId, Long petId, Long photoId) {
        PetMst pet = petKeeper.assertKeeper(userId, petId);
        PhotoDtl photo = photoRepository.findByIdAndEntityType(photoId, EntityType.PET)
                .filter(p -> p.getEntityId().equals(petId))
                .orElseThrow(() -> new BusinessException(ErrorCode.PHOTO_NOT_FOUND));
        pet.setProfilePhoto(photo.getId());
        return PetResponse.from(pet, null, List.of(), s3Service.resolveUrl(photo.getS3Key()),
                petKeeper.isOwner(userId, petId));
    }

    @Transactional
    public void delete(Long userId, Long petId) {
        PetMst pet = loadOwnedPet(userId, petId);
        pet.softDelete();
        // 이 개체에 연결된 모든 루틴에서 연결 제거 + 활성 재계산 (빈 루틴 비활성화)
        routineMaintenance.onPetDeleted(petId);
    }

    /**
     * 개체 일괄 삭제 (Soft Delete).
     *
     * <p><b>전부 성공 아니면 전부 실패.</b> 소유자가 아닌 개체가 하나라도 섞여 있으면
     * 아무것도 지우지 않고 403으로 끝낸다 — 벌크 공유 초대({@code inviteBulk})와 같은 규약이다.
     * 삭제는 되돌릴 수 없으므로, 일부만 지워진 채 "몇 마리는 실패했다"고 알리는 것보다
     * 사용자가 선택을 고쳐 다시 시도하게 하는 편이 안전하다.
     *
     * <p>소유권을 <b>먼저 전부 확인한 뒤</b> 삭제한다. 확인과 삭제를 번갈아 하면
     * 뒤쪽에서 예외가 나도 같은 트랜잭션이라 롤백되긴 하지만,
     * 루틴 정리({@code onPetDeleted})가 부분 수행된 상태를 만들 이유가 없다.
     */
    @Transactional
    public PetBulkDeleteResponse deleteAll(Long userId, List<Long> petIds) {
        // 중복 제거, 요청 순서 보존
        List<Long> ids = new ArrayList<>(new LinkedHashSet<>(petIds));

        List<PetMst> pets = new ArrayList<>(ids.size());
        for (Long petId : ids) {
            pets.add(loadOwnedPet(userId, petId));   // 하나라도 아니면 여기서 중단
        }
        for (int i = 0; i < ids.size(); i++) {
            pets.get(i).softDelete();
            routineMaintenance.onPetDeleted(ids.get(i));
        }
        return PetBulkDeleteResponse.of(ids);
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
        petKeeper.assertKeeper(userId, petId);
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
        PetMst pet = petKeeper.assertKeeper(userId, petId);
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

    /** 소유자 전용 작업 검증 (프로필 수정·삭제·관계 편집) */
    private PetMst loadOwnedPet(Long userId, Long petId) {
        return petKeeper.assertOwner(userId, petId);
    }

    private void attachMorphs(PetMst pet, List<Long> morphIds, SpeciesCd species) {
        if (morphIds == null || morphIds.isEmpty()) return;
        // 요청 내 중복 morphId 제거 (동일 복합키 중복 INSERT 방지)
        for (Long morphId : new LinkedHashSet<>(morphIds)) {
            MorphCd morph = morphRepository.findById(morphId)
                    .orElseThrow(() -> new BusinessException(ErrorCode.MORPH_NOT_FOUND));
            if (species != null && !morph.getSpeciesId().equals(species.getId())) {
                throw new BusinessException(ErrorCode.MORPH_SPECIES_MISMATCH);
            }
            pet.getMorphs().add(PetMorphRls.of(pet, morph));
        }
    }

    /**
     * 모프 목록을 diff 방식으로 동기화한다.
     * clear() 후 재add하면 (petId,morphId) 복합키가 삭제 예정 인스턴스와 충돌하므로,
     * 빠진 것만 제거하고 새 것만 추가한다.
     */
    private void syncMorphs(PetMst pet, List<Long> morphIds, SpeciesCd species) {
        Set<Long> desired = new LinkedHashSet<>(morphIds);
        Set<Long> current = pet.getMorphs().stream()
                .map(r -> r.getMorph().getId())
                .collect(Collectors.toSet());

        // 제거: 현재 있는데 desired에 없는 것 (orphanRemoval로 삭제)
        pet.getMorphs().removeIf(r -> !desired.contains(r.getMorph().getId()));

        // 추가: desired에 있는데 현재 없는 것만
        for (Long morphId : desired) {
            if (current.contains(morphId)) continue;
            MorphCd morph = morphRepository.findById(morphId)
                    .orElseThrow(() -> new BusinessException(ErrorCode.MORPH_NOT_FOUND));
            if (species != null && !morph.getSpeciesId().equals(species.getId())) {
                throw new BusinessException(ErrorCode.MORPH_SPECIES_MISMATCH);
            }
            pet.getMorphs().add(PetMorphRls.of(pet, morph));
        }
    }
}
