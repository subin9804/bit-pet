package io.bitpet.pet.service;

import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.MorphCd;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMorphRls;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.domain.PetRelationRls;
import io.bitpet.pet.domain.RelationType;
import io.bitpet.pet.domain.SpeciesCd;
import io.bitpet.pet.dto.GenealogyResponse;
import io.bitpet.pet.dto.PetBulkDeleteResponse;
import io.bitpet.pet.dto.PetCardResponse;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetOwnerResponse;
import io.bitpet.pet.dto.PetRelationRequest;
import io.bitpet.pet.dto.PetRelationResponse;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.dto.PetUpdateRequest;
import io.bitpet.pet.dto.UserProfileResponse;
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
import java.util.Map;
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
    private final UserMstRepository userRepository;
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

        // 등록 화면에서 고른 부모를 여기서 함께 걸어준다. 앱은 예전부터 fatherPetId/motherPetId를
        // 보내고 있었는데 서버가 조용히 버리고 있었다 — 저장된 줄 알고 넘어가면 가계도가 빈다.
        linkParentAtCreate(userId, pet.getId(), req.fatherPetId(), RelationType.FATHER);
        linkParentAtCreate(userId, pet.getId(), req.motherPetId(), RelationType.MOTHER);

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
        if (!"N".equals(pet.getPrivateYn()) || pet.isOrphaned()) {
            throw new BusinessException(ErrorCode.PET_NOT_FOUND); // 비공개·고아는 404로 동일 처리
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

    /**
     * 이별하기 — 폐사 처리 (기록은 그대로 보존).
     *
     * <p><b>사육자면 할 수 있다.</b> 폐사는 소유권 판단이 아니라 <b>일어난 사실의 기록</b>이고,
     * 그 사실을 가장 먼저 아는 사람이 소유자라는 보장이 없다. 함께 키우는 사람이 발견하고도
     * 소유자 계정을 기다려야 한다면 기록 시점이 어긋난다.
     * 되돌리는 {@link #revertDeceased}가 있어 잘못 눌러도 복구된다.
     */
    @Transactional
    public PetResponse markDeceased(Long userId, Long petId, java.time.LocalDate deceasedAt) {
        PetMst pet = petKeeper.assertKeeper(userId, petId);
        pet.markDeceased(deceasedAt);
        return PetResponse.from(pet);
    }

    /** 이별 취소 — 폐사 표시 해제. 표시할 수 있는 사람이 되돌릴 수도 있어야 한다 */
    @Transactional
    public PetResponse revertDeceased(Long userId, Long petId) {
        PetMst pet = petKeeper.assertKeeper(userId, petId);
        pet.revertDeceased();
        return PetResponse.from(pet);
    }

    // -------------------------------------------------------------------------
    // D3: 부모-자식 관계
    // -------------------------------------------------------------------------

    /**
     * 부모 등록.
     *
     * <p><b>자식은 내가 사육하는 개체여야 하고(OWNER/KEEPER), 부모는 실존 개체이기만 하면 된다.</b>
     * 부모 쪽 소유자는 묻지 않는다 — 남의 개체도, 폐사한 개체도, 주인이 탈퇴한 개체도 걸 수 있다.
     * 승인·차단 절차는 두지 않았다(검증 도메인 미구현). 실제로 브리딩 라인은 분양을 타고
     * 사람을 건너다니는데, 부모 쪽 주인의 승인을 받아야 등록된다면 대부분의 가계도가
     * 미완성으로 남는다. 사칭은 조회 응답에 소유자를 실어 보내는 것으로 억제한다
     * ({@link io.bitpet.pet.dto.PetOwnerResponse}).
     *
     * <p>부모를 텍스트로 적을 수는 없다 — 항상 pet_mst 참조다. 실존하지 않는 개체를
     * 부모로 적어두면 그 뒤로 이어지는 라인 전체가 검증 불가능한 문자열이 된다.
     */
    @Transactional
    public PetRelationResponse addRelation(Long userId, PetRelationRequest req) {
        if (req.parentPetId().equals(req.childPetId())) {
            throw new BusinessException(ErrorCode.PET_RELATION_SELF);
        }
        PetMst child = petKeeper.assertKeeper(userId, req.childPetId());
        PetMst parent = petRepository.findById(req.parentPetId())
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));

        // 주인이 탈퇴해 익명화된 개체는 새로 걸 수 없다. 기존 참조는 그대로 두므로
        // 고아 개체의 참조 수는 단조 감소하고, 0이 되면 정리 배치가 지워 자연 소멸한다.
        // 클라이언트 필터링만으로는 부족해 여기서 막는다.
        if (parent.isOrphaned()) {
            throw new BusinessException(ErrorCode.PET_ORPHANED);
        }

        if (relationRepository.existsByParentPetIdAndChildPetIdAndRelationType(
                req.parentPetId(), req.childPetId(), req.relationType())) {
            throw new BusinessException(ErrorCode.PET_RELATION_DUPLICATE);
        }
        // A가 B의 부모인데 B를 A의 부모로 다시 거는 경우. 깊은 순환까지 막지는 않지만,
        // 남의 개체를 자유롭게 걸 수 있게 된 이상 최소한 바로 되짚는 건 막는다.
        if (relationRepository.existsByParentPetIdAndChildPetId(
                req.childPetId(), req.parentPetId())) {
            throw new BusinessException(ErrorCode.PET_RELATION_CYCLE);
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

    /**
     * 부모 등록 해제 — <b>자식 쪽 사육자만</b> 할 수 있다.
     *
     * <p>부모로 걸린 개체의 주인에게 삭제 권한을 주면 그게 곧 차단 절차가 된다.
     * 이번 정책에는 승인도 차단도 없으므로, 자기 가계도를 고칠 수 있는 사람만 관계를 지운다.
     * <b>판정 축이 '자식 쪽'이라는 게 핵심이고 OWNER냐 KEEPER냐는 아니다</b> —
     * 등록을 사육자에게 열었으므로 해제도 같은 범위여야 자기가 건 걸 되돌릴 수 있다.
     */
    @Transactional
    public void deleteRelation(Long userId, Long relationId) {
        PetRelationRls relation = relationRepository.findById(relationId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_RELATION_NOT_FOUND));
        petKeeper.assertKeeper(userId, relation.getChildPet().getId());
        relationRepository.delete(relation);
    }

    /**
     * 가계도 조회.
     *
     * <p>부모·자식에는 남의 개체가 섞인다(부모 등록에 승인이 없으므로). 그래서 노드는
     * 사육 기록이 빠진 {@link PetCardResponse}로 내리고, 소유자 표시 정보를 함께 싣는다.
     * {@code isMe}/{@code isOrphaned}는 여기서 판정한다 — 앱이 currentUserId와 비교하게 두면
     * 같은 분기가 화면마다 흩어진다.
     */
    public GenealogyResponse getGenealogy(Long userId, Long petId) {
        PetMst pet = petKeeper.assertKeeper(userId, petId);
        List<PetRelationRls> parentRels = relationRepository.findAllByChildPetId(petId);
        List<PetRelationRls> childRels  = relationRepository.findAllByParentPetId(petId);

        List<PetMst> nodes = new ArrayList<>();
        parentRels.forEach(r -> nodes.add(r.getParentPet()));
        childRels.forEach(r -> nodes.add(r.getChildPet()));
        Map<Long, PetOwnerResponse> owners = resolveOwners(userId, nodes);

        return new GenealogyResponse(
                PetResponse.from(pet, null, parentRels, resolveProfileImageUrl(pet),
                        petKeeper.isOwner(userId, petId)),
                parentRels.stream()
                        .map(r -> toCard(userId, r.getParentPet(), r.getId(), r.getRelationType(), owners))
                        .toList(),
                childRels.stream()
                        .map(r -> toCard(userId, r.getChildPet(), r.getId(), r.getRelationType(), owners))
                        .toList()
        );
    }

    /**
     * 남의 개체 공개 조회 — 가계도 카드에서 공개 개체를 눌렀을 때.
     * 비공개 개체는 404로 뭉갠다({@code findBySerial}와 같은 규약).
     */
    public PetCardResponse getPublicCard(Long userId, Long petId) {
        PetMst pet = petRepository.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!"N".equals(pet.getPrivateYn()) && !petKeeper.isKeeper(userId, petId)) {
            throw new BusinessException(ErrorCode.PET_NOT_FOUND);
        }
        return toCard(userId, pet, null, null, resolveOwners(userId, List.of(pet)));
    }

    /**
     * 일련번호로 개체 카드 조회 — 부모 선택 화면에서 <b>남의 개체를 걸기 위한</b> 유일한 입구다.
     *
     * <p>부모는 소유자와 무관하게 등록할 수 있지만, 그렇다고 남의 개체 목록을 훑게 해줄 수는 없다.
     * 일련번호를 알고 있다는 것 자체가 "실물 개체를 넘겨받았거나 분양자에게 들었다"는 최소한의
     * 근거라서, 검색은 정확한 일련번호 일치로만 연다.
     *
     * <p>{@code findBySerial}과 달리 {@link PetCardResponse}로 내린다 — 저쪽은 사육 기록이
     * 딸린 PetResponse라 남의 개체에 그대로 쓰면 메모·입양일까지 새어 나간다.
     */
    public PetCardResponse findCardBySerial(Long userId, String serialNo) {
        PetMst pet = petRepository.findBySerialNo(serialNo.toUpperCase())
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!"N".equals(pet.getPrivateYn()) && !petKeeper.isKeeper(userId, pet.getId())) {
            throw new BusinessException(ErrorCode.PET_NOT_FOUND); // 비공개는 404로 동일 처리
        }
        // 이 API 는 부모 선택 화면의 검색 입구다 — 고아 개체는 선택 대상에서 빠져야 한다.
        // (이미 가계도에 걸린 고아는 카드에서 바로 열리므로 조회 자체가 막히지는 않는다)
        if (pet.isOrphaned()) {
            throw new BusinessException(ErrorCode.PET_NOT_FOUND);
        }
        return toCard(userId, pet, null, null, resolveOwners(userId, List.of(pet)));
    }

    /**
     * 공개 프로필 — 가계도 카드의 '@닉네임' 탭. 공개 개체만 싣는다.
     *
     * <p>닉네임을 비공개로 둔 사용자는 애초에 응답에 userId 가 실리지 않아 이 화면에 닿을 수
     * 없지만, 아이디를 직접 찍어 넣는 우회를 막으려면 여기서도 한 번 더 잘라야 한다.
     */
    public UserProfileResponse getUserProfile(Long requesterId, Long userId) {
        UserMst user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND));
        if (!user.isShowNicknameInPedigree() && !user.getId().equals(requesterId)) {
            throw new BusinessException(ErrorCode.USER_PROFILE_HIDDEN);
        }
        List<PetMst> publicPets = petRepository.findAllByUserIdAndPrivateYn(userId, "N");
        Map<Long, PetOwnerResponse> owners = resolveOwners(requesterId, publicPets);
        return new UserProfileResponse(
                user.getId(),
                user.getName(),
                user.getProfileImageUrl(),
                user.getId().equals(requesterId),
                publicPets.stream()
                        .map(p -> toCard(requesterId, p, null, null, owners))
                        .toList()
        );
    }

    /**
     * 개체별 소유자 표시 정보.
     *
     * <p>소유자 없음(isOrphaned)은 두 가지를 같이 덮는다 — {@code user_id IS NULL}(탈퇴 익명화)과
     * 탈퇴로 소프트 삭제된 계정(UserMst의 {@code @SQLRestriction}에 걸려 조회되지 않는다).
     * 화면에서는 둘 다 '정보 없음'이라 구분할 이유가 없다.
     *
     * <p>소유자가 닉네임 비공개({@code show_nickname_in_pedigree = false})면 '비공개'로 치환하고
     * userId 도 내리지 않는다 — 소유자 없음('정보 없음')과는 다른 상태다.
     */
    private Map<Long, PetOwnerResponse> resolveOwners(Long requesterId, List<PetMst> pets) {
        Set<Long> ownerIds = pets.stream()
                .map(PetMst::getUserId)
                .filter(java.util.Objects::nonNull)
                .collect(Collectors.toSet());
        Map<Long, UserMst> owners = userRepository.findAllById(ownerIds).stream()
                .collect(Collectors.toMap(UserMst::getId, u -> u));

        Map<Long, PetOwnerResponse> byPetId = new java.util.HashMap<>();
        for (PetMst p : pets) {
            Long ownerId = p.getUserId();
            UserMst owner = ownerId == null ? null : owners.get(ownerId);
            byPetId.put(p.getId(), PetOwnerResponse.of(
                    ownerId,
                    owner == null ? null : owner.getName(),
                    requesterId,
                    owner != null && owner.isShowNicknameInPedigree()));
        }
        return byPetId;
    }

    /**
     * 개체를 "한 장 카드"로. NFC 스캔처럼 개체를 그 자리에서 확인시켜야 하는 자리를 위한 것이다.
     *
     * <p>{@code includeOwner = false} 면 소유자 정보를 <b>아예 담지 않는다</b>(null).
     * 남의 개체를 스캔했을 때 쓴다 — 개체가 실재한다는 것까지는 알려주되 누구 것인지는 밝히지 않는다.
     */
    public PetCardResponse cardOf(Long requesterId, PetMst pet, boolean includeOwner) {
        PetOwnerResponse owner = includeOwner
                ? resolveOwners(requesterId, List.of(pet)).get(pet.getId())
                : null;
        return PetCardResponse.of(pet, null, null, resolveProfileImageUrl(pet),
                petKeeper.isKeeper(requesterId, pet.getId()), owner);
    }

    private PetCardResponse toCard(Long userId, PetMst pet, Long relationId,
                                   RelationType relationType,
                                   Map<Long, PetOwnerResponse> owners) {
        // 사육자면 전체 상세로, 사육자가 아니어도 공개 개체면 공개 조회로 들어갈 수 있다.
        // 둘 다 아니면 앱이 이 카드에 담긴 정보(이름·종·모프·성별·해칭일)만으로 바텀시트를 띄운다.
        return PetCardResponse.of(pet, relationId, relationType,
                resolveProfileImageUrl(pet), petKeeper.isKeeper(userId, pet.getId()),
                owners.getOrDefault(pet.getId(), PetOwnerResponse.orphaned()));
    }

    // -------------------------------------------------------------------------
    // 내부 헬퍼
    // -------------------------------------------------------------------------

    /** 개체 등록 시 부모 연결 — 등록 후 addRelation과 같은 정책(부모는 실존 개체이기만 하면 된다) */
    private void linkParentAtCreate(Long userId, Long childPetId, Long parentPetId, RelationType type) {
        if (parentPetId == null) return;
        addRelation(userId, new PetRelationRequest(parentPetId, childPetId, type));
    }

    /** 소유자 전용 작업 검증 — 개체를 없애는 동작(삭제·벌크 삭제)에만 쓴다 */
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
