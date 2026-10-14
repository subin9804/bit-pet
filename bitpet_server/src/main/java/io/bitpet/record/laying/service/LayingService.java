package io.bitpet.record.laying.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.MorphCd;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMorphRls;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.domain.PetRelationRls;
import io.bitpet.pet.domain.RelationType;
import io.bitpet.pet.domain.SpeciesCd;
import io.bitpet.pet.repository.MorphCdRepository;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.repository.PetRelationRlsRepository;
import io.bitpet.pet.repository.SpeciesCdRepository;
import io.bitpet.pet.service.SerialNumberGenerator;
import io.bitpet.record.laying.domain.HatchStatus;
import io.bitpet.record.laying.domain.LayingDtl;
import io.bitpet.record.laying.domain.LayingHatchDtl;
import io.bitpet.record.laying.domain.LayingNoteDtl;
import io.bitpet.record.laying.dto.HatchCreateRequest;
import io.bitpet.record.laying.dto.HatchResponse;
import io.bitpet.record.laying.dto.HatchUpdateRequest;
import io.bitpet.record.laying.dto.LayingCreateRequest;
import io.bitpet.record.laying.dto.LayingNoteRequest;
import io.bitpet.record.laying.dto.LayingNoteResponse;
import io.bitpet.record.laying.dto.LayingResponse;
import io.bitpet.record.laying.dto.LayingUpdateRequest;
import io.bitpet.record.laying.dto.RegisterPetRequest;
import io.bitpet.record.laying.repository.LayingDtlRepository;
import io.bitpet.record.laying.repository.LayingDtlSpecs;
import io.bitpet.record.laying.repository.LayingHatchDtlRepository;
import io.bitpet.record.laying.repository.LayingNoteDtlRepository;
import io.bitpet.record.domain.WeightDtl;
import io.bitpet.record.domain.WeightSource;
import io.bitpet.record.repository.WeightDtlRepository;
import io.bitpet.record.mating.domain.MatingDtl;
import io.bitpet.record.mating.repository.MatingDtlRepository;
import io.bitpet.pet.dto.PetResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class LayingService {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    /**
     * 알 칸 정렬 — 번호가 있는 알이 번호순으로 먼저, 번호 없는 옛 기록은 뒤에 만든 순서대로.
     * (egg_index 는 V16 에서 생긴 컬럼이라 백필 이후에도 null 이 남을 수 있다)
     */
    private static final Comparator<LayingHatchDtl> EGG_ORDER =
            Comparator.comparing(LayingHatchDtl::getEggIndex,
                            Comparator.nullsLast(Comparator.naturalOrder()))
                    .thenComparing(LayingHatchDtl::getCreatedAt,
                            Comparator.nullsLast(Comparator.naturalOrder()))
                    .thenComparing(LayingHatchDtl::getId);

    private final LayingDtlRepository layingRepo;
    private final LayingHatchDtlRepository hatchRepo;
    private final LayingNoteDtlRepository noteRepo;
    private final WeightDtlRepository weightRepo;
    private final MatingDtlRepository matingRepo;
    private final PetMstRepository petRepo;
    private final io.bitpet.pet.service.PetKeeperService petKeeper;
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

        // 포유류(출산)는 알이 없다 — 유정란 수·인큐베이션 값을 통째로 버린다.
        boolean mammal = isMammal(pet);
        validateEggCounts(req.eggCountTotal(), mammal ? null : req.eggCountFertile());

        if (req.matingId() != null) {
            validateMatingFemale(req.matingId(), petId);
        }

        LayingDtl laying = layingRepo.save(LayingDtl.builder()
                .petId(petId)
                .createdByUserId(userId)
                .matingId(req.matingId())
                .laidAt(req.laidAt().toInstant())
                .eggCountTotal(req.eggCountTotal())
                .eggCountFertile(mammal ? null : req.eggCountFertile())
                .incubationTemp(mammal ? null : req.incubationTemp())
                .incubationHumidity(mammal ? null : req.incubationHumidity())
                .memo(req.memo())
                .build());

        // 알 칸은 산란과 동시에 생긴다 — 화면이 알을 칸으로 그리려면 행이 미리 있어야 한다.
        // 포유류는 알 칸을 만들지 않는다 (아래 syncEggRows 주석 참고).
        syncEggRows(laying, userId, mammal);

        return LayingResponse.of(laying, buildHatches(laying.getId()), List.of(), pet);
    }

    // -------------------------------------------------------------------------
    // 산란 목록
    // -------------------------------------------------------------------------

    /**
     * 기록 목록은 <b>페이지 없이 배열 그대로</b> 내린다. 같은 도메인의 체중·급여·청소가
     * 이미 그렇고, 앱은 캘린더를 그리느라 어차피 전량을 받는다. 필터(matingId/기간)는 남긴다.
     */
    public List<LayingResponse> getLayings(Long petId, Long userId,
                                            Long matingId,
                                            LocalDate from, LocalDate to) {
        PetMst pet = loadOwnedPet(userId, petId);
        Instant fromInst = from != null ? from.atStartOfDay(SEOUL).toInstant() : null;
        Instant toExcl   = to   != null ? to.plusDays(1).atStartOfDay(SEOUL).toInstant() : null;

        return layingRepo.findAll(LayingDtlSpecs.filter(petId, matingId, fromInst, toExcl),
                        Sort.by(Sort.Direction.DESC, "laidAt"))
                .stream()
                .map(l -> LayingResponse.of(l, buildHatches(l.getId()), buildNotes(l.getId()), pet))
                .toList();
    }

    /**
     * '내 개체 → 알' 탭 — 개체를 가로질러 내가 돌보는 클러치 전부.
     *
     * <p>개체별 목록과 달리 어미 이름·종까지 붙여 내린다. 탭의 클러치 카드가 어미를 적는데,
     * 개체를 하나씩 다시 조회하면 N+1 이 된다.
     *
     * <p><b>포유류의 출산은 빠진다.</b> 이 탭의 용도는 "지금 품고 있는 알"을 한 줄로 훑는
     * 것인데, 출산은 적는 시점에 이미 끝난 일이라 품고 있을 것이 없다. 알 칸도 만들지
     * 않으므로(아래 {@code syncEggRows}) 카드에 그릴 내용 자체가 없다. 포유류의 출산
     * 기록은 개체 상세의 기록 요약·캘린더·출산 기록 목록에서 본다.
     */
    public List<LayingResponse> getMyLayings(Long userId) {
        List<Long> petIds = petKeeper.keptPetIds(userId);
        if (petIds.isEmpty()) return List.of();

        Map<Long, PetMst> pets = petRepo.findAllById(petIds).stream()
                .filter(p -> !isMammal(p))
                .collect(Collectors.toMap(PetMst::getId, Function.identity()));
        if (pets.isEmpty()) return List.of();

        return layingRepo.findAllByPetIdInOrderByLaidAtDesc(List.copyOf(pets.keySet())).stream()
                .map(l -> LayingResponse.of(l, buildHatches(l.getId()), buildNotes(l.getId()),
                        pets.get(l.getPetId())))
                .toList();
    }

    // -------------------------------------------------------------------------
    // 산란 단건
    // -------------------------------------------------------------------------

    public LayingResponse getLaying(Long layingId, Long userId) {
        LayingDtl laying = loadAccessibleLaying(layingId, userId);
        return LayingResponse.of(laying, buildHatches(layingId), buildNotes(layingId),
                petRepo.findById(laying.getPetId()).orElse(null));
    }

    // -------------------------------------------------------------------------
    // 산란 수정
    // -------------------------------------------------------------------------

    @Transactional
    public LayingResponse updateLaying(Long layingId, Long userId, LayingUpdateRequest req) {
        LayingDtl laying = loadAccessibleLaying(layingId, userId);
        PetMst pet = petRepo.findById(laying.getPetId()).orElse(null);

        // 생성과 같은 규칙 — 포유류는 알이 없다. 구버전 앱이 유정란·인큐베이션 값을
        // 그대로 다시 올려도 여기서 버려야 거짓 데이터가 되살아나지 않는다.
        boolean mammal = pet != null && isMammal(pet);
        validateEggCounts(req.eggCountTotal(), mammal ? null : req.eggCountFertile());

        if (req.matingId() != null) {
            validateMatingFemale(req.matingId(), laying.getPetId());
        }

        laying.update(req.matingId(), req.laidAt().toInstant(), req.eggCountTotal(),
                mammal ? null : req.eggCountFertile(),
                mammal ? null : req.incubationTemp(),
                mammal ? null : req.incubationHumidity(), req.memo());

        syncEggRows(laying, userId, mammal);

        return LayingResponse.of(laying, buildHatches(layingId), buildNotes(layingId), pet);
    }

    // -------------------------------------------------------------------------
    // 산란 삭제
    // -------------------------------------------------------------------------

    @Transactional
    public void deleteLaying(Long layingId, Long userId) {
        LayingDtl laying = loadAccessibleLaying(layingId, userId);
        layingRepo.delete(laying); // hard delete — hatch·note는 DB ON DELETE CASCADE로 자동 삭제
    }

    // -------------------------------------------------------------------------
    // 해칭 추가
    // -------------------------------------------------------------------------

    @Transactional
    public HatchResponse createHatch(Long layingId, Long userId, HatchCreateRequest req) {
        loadAccessibleLaying(layingId, userId);

        if (req.status() == HatchStatus.HATCHED && req.hatchedAt() == null) {
            throw new BusinessException(ErrorCode.HATCH_INVALID_STATUS_TRANSITION);
        }

        LayingHatchDtl hatch = hatchRepo.save(LayingHatchDtl.builder()
                .layingId(layingId)
                .eggIndex(req.eggIndex() != null ? req.eggIndex() : nextEggIndex(layingId))
                .createdByUserId(userId)
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
    // 알 칸 탭 — 상태 순환
    // -------------------------------------------------------------------------

    /**
     * 알 칸을 누를 때마다 <b>대기 → 부화 → 무정 → 대기</b>. 부화일은 누른 날로 자동 기록한다.
     *
     * <p>상태 하나 바꾸려고 폼을 띄우지 않겠다는 뜻이라, 서버도 "다음 상태"를 받지 않고
     * 스스로 센다. 날짜를 고치거나 FAILED(발달 중 폐사)로 바꾸는 건 수정 API 쪽 일이다.
     *
     * <p>이미 개체로 등록된 알은 순환에서 뺀다. 여기서 상태를 되돌리면 pet_mst 에 남은 개체와
     * 어긋나므로, 개체를 먼저 지우거나 연결을 끊어야 한다.
     */
    @Transactional
    public HatchResponse cycleHatchStatus(Long layingId, Long hatchId, Long userId) {
        loadAccessibleLaying(layingId, userId);
        LayingHatchDtl hatch = loadHatch(hatchId, layingId);

        // 개체가 소프트 삭제되면 LayingMaintenanceService 가 이 링크를 끊어 주므로,
        // 여기 걸리는 건 실제로 살아 있는 개체가 달린 알뿐이다
        if (hatch.getHatchedPetId() != null) {
            throw new BusinessException(ErrorCode.HATCH_ALREADY_REGISTERED);
        }

        hatch.cycleStatus(Instant.now());
        return HatchResponse.of(hatch, null);
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
    // 날짜별 관찰 메모
    // -------------------------------------------------------------------------

    public List<LayingNoteResponse> getNotes(Long layingId, Long userId) {
        loadAccessibleLaying(layingId, userId);
        return buildNotes(layingId);
    }

    @Transactional
    public LayingNoteResponse createNote(Long layingId, Long userId, LayingNoteRequest req) {
        loadAccessibleLaying(layingId, userId);
        LayingNoteDtl note = noteRepo.save(LayingNoteDtl.builder()
                .layingId(layingId)
                .notedAt(req.notedAt())
                .content(req.content())
                .createdByUserId(userId)
                .build());
        return LayingNoteResponse.of(note);
    }

    @Transactional
    public LayingNoteResponse updateNote(Long layingId, Long noteId, Long userId, LayingNoteRequest req) {
        loadAccessibleLaying(layingId, userId);
        LayingNoteDtl note = loadNote(noteId, layingId);
        note.update(req.notedAt(), req.content());
        return LayingNoteResponse.of(note);
    }

    @Transactional
    public void deleteNote(Long layingId, Long noteId, Long userId) {
        loadAccessibleLaying(layingId, userId);
        loadNote(noteId, layingId).softDelete();
    }

    // -------------------------------------------------------------------------
    // 편의 API: 해칭 → 신규 개체 등록 + lineage 자동 연결
    // -------------------------------------------------------------------------

    /**
     * 부화한 알을 개체로 올린다.
     *
     * <p>등록 시트는 <b>이름과 성별만</b> 받는다. 종·해칭일·부모는 클러치가 이미 아는 값이라
     * 비워 보내면 여기서 채운다 — 종은 어미와 같고, 해칭일은 그 알의 부화일이다.
     */
    @Transactional
    public PetResponse registerPet(Long layingId, Long hatchId, Long userId, RegisterPetRequest req) {
        LayingDtl laying = loadAccessibleLaying(layingId, userId);
        LayingHatchDtl hatch = loadHatch(hatchId, layingId);

        if (hatch.getHatchedPetId() != null) {
            throw new BusinessException(ErrorCode.HATCH_ALREADY_REGISTERED);
        }

        PetMst mother = petRepo.findById(laying.getPetId()).orElse(null);

        SpeciesCd species = req.speciesId() != null
                ? speciesRepo.findById(req.speciesId())
                        .orElseThrow(() -> new BusinessException(ErrorCode.SPECIES_NOT_FOUND))
                : (mother != null ? mother.getSpecies() : null);   // 종은 어미와 같다
        MorphCd morph = req.morphId() != null
                ? morphRepo.findById(req.morphId())
                        .orElseThrow(() -> new BusinessException(ErrorCode.MORPH_NOT_FOUND))
                : null;

        // 해칭일 = 그 알의 부화일. 알 칸을 누른 날이 그대로 개체의 해칭일이 된다
        LocalDate hatchingDate = req.birthDate() != null
                ? req.birthDate()
                : (hatch.getHatchedAt() != null
                        ? hatch.getHatchedAt().atZone(SEOUL).toLocalDate()
                        : LocalDate.now(SEOUL));

        // 부화 개체도 결국 내 개체다 — 여기를 빼면 상한을 우회하는 경로가 된다
        petKeeper.assertCanOwnMore(userId);

        String serial = serialNumberGenerator.generate();
        PetMst newPet = petRepo.save(PetMst.builder()
                .serialNo(serial)
                .userId(userId)
                .species(species)
                .name(req.name())
                .gender(req.gender())
                .hatchingDate(hatchingDate)
                .description(req.memo())
                .build());
        // 권한 판정 단일 소스 — 새 개체 OWNER 등록 (누락 시 소유자도 접근 거부됨)
        petKeeper.registerOwner(newPet.getId(), userId);

        if (morph != null) {
            newPet.getMorphs().add(PetMorphRls.of(newPet, morph));
        }

        // 첫 몸무게는 선택이다. 적어 보냈으면 해칭 시점의 체중 기록 한 건으로 남긴다 —
        // pet_mst 에 체중 칸을 따로 두지 않고 weight_dtl 로만 관리하는 기존 방식 그대로다
        if (req.weightG() != null) {
            weightRepo.save(WeightDtl.builder()
                    .petId(newPet.getId())
                    .weightG(req.weightG())
                    .measuredAt(hatchingDate.atStartOfDay(SEOUL).toInstant())
                    .source(WeightSource.MANUAL)
                    .createdByUserId(userId)
                    .build());
        }

        hatch.linkPet(newPet.getId());
        createLineage(layingId, newPet.getId());

        return PetResponse.from(newPet);
    }

    // -------------------------------------------------------------------------
    // private helpers
    // -------------------------------------------------------------------------

    /**
     * 알 개수에 맞춰 알 칸 행을 맞춘다.
     *
     * <p>늘어나면 빈 번호를 PENDING 으로 채우고, 줄어들면 <b>남는 PENDING 행만</b> 지운다.
     * 부화·무정으로 이미 결과가 적힌 알은 개수를 잘못 입력했다는 이유로 지우지 않는다
     * (지우면 등록된 개체와의 연결이 끊긴다). 그래서 실제 행 수가 총 개수보다 많을 수 있다.
     *
     * <p><b>포유류(출산)는 행을 만들지 않는다.</b> 출산을 적는 시점에 새끼는 이미 태어나
     * 있어서 {@code PENDING}(품고 있는 중)이라는 상태가 성립하지 않고, 알 화면을
     * 보여주지 않으므로 만들어 둬도 손댈 길이 없는 죽은 데이터가 된다. 게다가 남겨두면
     * '내 개체 → 알' 탭의 클러치 목록에 섞여 들어간다. 포유류의 출산 기록은
     * {@code laid_at}(출산일) + {@code egg_count_total}(새끼 수) 두 값이 전부다.
     */
    private void syncEggRows(LayingDtl laying, Long userId, boolean mammal) {
        if (mammal) return;

        List<LayingHatchDtl> rows = hatchRepo.findAllByLayingIdOrderByCreatedAtAsc(laying.getId());
        int total = laying.getEggCountTotal();

        Set<Integer> taken = rows.stream()
                .map(LayingHatchDtl::getEggIndex)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        for (int i = 1; i <= total; i++) {
            if (!taken.contains(i)) {
                hatchRepo.save(LayingHatchDtl.builder()
                        .layingId(laying.getId())
                        .eggIndex(i)
                        .status(HatchStatus.PENDING)
                        .createdByUserId(userId)
                        .build());
            }
        }

        rows.stream()
                .filter(h -> h.getStatus() == HatchStatus.PENDING)
                .filter(h -> h.getEggIndex() != null && h.getEggIndex() > total)
                .forEach(LayingHatchDtl::softDelete);
    }

    private int nextEggIndex(Long layingId) {
        return hatchRepo.findAllByLayingIdOrderByCreatedAtAsc(layingId).stream()
                .map(LayingHatchDtl::getEggIndex)
                .filter(Objects::nonNull)
                .max(Integer::compareTo)
                .orElse(0) + 1;
    }

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
                .sorted(EGG_ORDER)
                .map(h -> {
                    PetMst p = h.getHatchedPetId() != null
                            ? petRepo.findById(h.getHatchedPetId()).orElse(null) : null;
                    return HatchResponse.of(h, p);
                })
                .toList();
    }

    private List<LayingNoteResponse> buildNotes(Long layingId) {
        return noteRepo.findAllByLayingIdOrderByNotedAtDescIdDesc(layingId).stream()
                .map(LayingNoteResponse::of)
                .toList();
    }

    /**
     * 포유류(새끼를 낳는 종)인가 — 출산이지 산란이 아니다.
     *
     * <p>⛔ 이 판정을 {@code laying_dtl} 의 컬럼으로 복제하지 말 것. 개체의 종에서
     * 파생되는 값이라 저장해두면 종을 수정하는 순간 기록 쪽이 거짓이 된다.
     */
    private boolean isMammal(PetMst pet) {
        return pet.getSpecies() != null && pet.getSpecies().isMammal();
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
        // 공유 개체 포함 — 사육자(OWNER/KEEPER)면 기록 작성·조회 가능
        return petKeeper.assertKeeper(userId, petId);
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

    private LayingNoteDtl loadNote(Long noteId, Long layingId) {
        return noteRepo.findByIdAndLayingId(noteId, layingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.LAYING_NOTE_NOT_FOUND));
    }
}
