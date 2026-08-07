package io.bitpet.nfc.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.nfc.domain.NfcTagBindHst;
import io.bitpet.nfc.domain.NfcTagMst;
import io.bitpet.nfc.domain.TagStockStatus;
import io.bitpet.nfc.dto.MyTagResponse;
import io.bitpet.nfc.dto.NfcScanResponse;
import io.bitpet.nfc.dto.TagResolveResponse;
import io.bitpet.nfc.repository.NfcTagBindHstRepository;
import io.bitpet.nfc.repository.NfcTagMstRepository;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.service.PetKeeperService;
import io.bitpet.pet.service.PetService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * NFC 태그 조회·연결·해제.
 *
 * <p>권한 규칙
 * <ul>
 *   <li>조회 : 연결된 개체의 <b>사육자</b>(OWNER/KEEPER)면 LINKED, 아니면 OWNED_BY_OTHER</li>
 *   <li>연결 : 개체의 <b>소유자</b>(OWNER)만. 이미 남이 쓰는 태그면 409</li>
 *   <li>해제 : 태그 소유자만</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class NfcTagService {

    private final NfcTagMstRepository tagRepository;
    private final NfcTagBindHstRepository bindHistoryRepository;
    private final PetMstRepository petRepository;
    private final PetKeeperService petKeeperService;
    private final PetService petService;
    private final TagCodeGenerator tagCodeGenerator;

    // -------------------------------------------------------------------------
    // 조회
    // -------------------------------------------------------------------------

    /**
     * 태그 스캔 — 상태를 판정한다.
     * 존재하지 않는 코드는 404 (위조 태그 차단), 차단된 코드는 REVOKED 안내.
     *
     * <p><b>완전한 read-only 다.</b> 스캔 횟수도 세지 않고(V51), 연결 정리도 여기서 하지 않는다.
     * 조회 경로에 쓰기가 섞이면 스캔 한 번마다 UPDATE 가 돈다.
     */
    public TagResolveResponse resolve(Long userId, String tagCd) {
        NfcTagMst tag = findTag(tagCd);

        // 실재하지만 차단된 코드다. 404 로 뭉개면 "위조 태그"로 오인시킨다
        if (tag.isRevoked()) {
            return TagResolveResponse.revoked(tag.getTagCd());
        }
        if (!tag.isLinked()) {
            return TagResolveResponse.unlinked(tag.getTagCd());
        }
        if (!petKeeperService.isKeeper(userId, tag.getPetId())) {
            return TagResolveResponse.ownedByOther(tag.getTagCd());
        }
        // 개체가 소프트 삭제됐으면 미연결로 보여준다. 실제 연결 정리는 쓰기 경로(link)에서 한다.
        // 고아 개체(주인 탈퇴)도 같다 — 스캔 결과는 신규 참조의 입구라 고아를 노출하지 않는다.
        Optional<PetMst> pet = petRepository.findById(tag.getPetId());
        if (pet.isEmpty() || pet.get().isOrphaned()) {
            return TagResolveResponse.unlinked(tag.getTagCd());
        }
        return TagResolveResponse.linked(tag.getTagCd(), pet.get().getId(), pet.get().getName());
    }

    /**
     * 태그 스캔 (v2) — 상태 + 개체 카드.
     *
     * <p>{@link #resolve} 와 판정 규칙은 같고, 개체 정보를 카드로 함께 내려주는 것만 다르다.
     * 스캔 시트가 "이 개체가 맞나요?"를 그 자리에서 보여줘야 하는데 개체 상세를 다시 부르면
     * 남의 개체에서 403 이 나기 때문이다.
     *
     * <p><b>남의 개체면 소유자 정보를 담지 않는다</b> — 필드를 내려보내고 앱에서 감추는 게 아니라
     * 서버가 응답에서 빼 버린다. 사육기록·체중·커뮤니티 활동은 애초에 카드에 없다.
     */
    public NfcScanResponse scan(Long userId, String tagCd) {
        NfcTagMst tag = findTag(tagCd);

        if (tag.isRevoked()) return NfcScanResponse.revoked(tag.getTagCd());
        if (!tag.isLinked())  return NfcScanResponse.unlinked(tag.getTagCd());

        // 개체가 소프트 삭제됐거나 고아(주인 탈퇴)면 미연결로 보여준다.
        // 스캔 결과는 신규 참조의 입구라 고아를 노출하지 않는다.
        Optional<PetMst> found = petRepository.findById(tag.getPetId());
        if (found.isEmpty() || found.get().isOrphaned()) {
            return NfcScanResponse.unlinked(tag.getTagCd());
        }

        PetMst pet = found.get();
        boolean keeper = petKeeperService.isKeeper(userId, pet.getId());
        return keeper
                ? NfcScanResponse.linked(tag.getTagCd(), petService.cardOf(userId, pet, true))
                : NfcScanResponse.ownedByOther(tag.getTagCd(), petService.cardOf(userId, pet, false));
    }

    /** 미설치자 랜딩 페이지용 — 개체 이름만. 없거나 미연결이거나 차단됐으면 empty */
    public Optional<String> peekPetName(String tagCd) {
        return tagRepository.findById(normalize(tagCd))
                .filter(tag -> !tag.isRevoked())
                .map(NfcTagMst::getPetId)
                .flatMap(petRepository::findById)
                .filter(pet -> !pet.isOrphaned())
                .map(PetMst::getName);
    }

    /** 마이페이지 — 내가 연결한 태그 목록 */
    public List<MyTagResponse> listMyTags(Long userId) {
        List<NfcTagMst> tags = tagRepository.findAllByUserIdOrderByLinkedAtDesc(userId);
        Map<Long, String> petNames = petRepository
                .findAllById(tags.stream().map(NfcTagMst::getPetId).filter(java.util.Objects::nonNull).toList())
                .stream()
                .collect(Collectors.toMap(PetMst::getId, PetMst::getName, (a, b) -> a));

        return tags.stream()
                .map(t -> new MyTagResponse(
                        t.getTagCd(),
                        t.getPetId(),
                        petNames.get(t.getPetId()),
                        t.getLinkedAt(),
                        t.getStatus(),
                        t.getChipType()))
                .toList();
    }

    // -------------------------------------------------------------------------
    // 연결 / 해제
    // -------------------------------------------------------------------------

    /**
     * @deprecated {@link #bind} 로 대체됐다. 내 다른 개체로의 이전을 확인 없이 수행하는
     *             기존 동작을 그대로 유지하기 위해 {@code rebind = true} 로 넘긴다.
     */
    @Deprecated
    @Transactional
    public TagResolveResponse link(Long userId, String tagCd, Long petId) {
        PetMst pet = bind(userId, tagCd, petId, true);
        return TagResolveResponse.linked(normalize(tagCd), pet.getId(), pet.getName());
    }

    /**
     * 태그 바인딩 (POST /api/v1/nfc/bindings).
     *
     * <p>소유권 검증은 {@code pet_mst.user_id} 가 아니라 <b>pet_keeper_rls 의 OWNER</b> 기준이다.
     * {@code user_id} 는 표시용 비정규화 값이라 그걸로 판정하면 서버가 실제로 거는 검사와 어긋난다.
     * 이 검증이 없으면 남의 개체에 내 태그를 붙일 수 있다.
     *
     * <p>이미 붙어 있는 태그의 처리는 세 갈래다.
     * <ul>
     *   <li>남의 개체 → 409 {@code TAG_ALREADY_LINKED}. 원 소유자가 먼저 해제해야 한다</li>
     *   <li>내 다른 개체 → {@code rebind=false} 면 409 {@code TAG_REBIND_CONFIRM_REQUIRED}.
     *       그냥 옮기면 사용자는 어느 개체의 이름표가 끊겼는지 모른 채 태그를 잃는다</li>
     *   <li>붙어 있던 개체가 이미 삭제됨 → 붙잡아 둘 이유가 없다. 확인 없이 푼다</li>
     * </ul>
     *
     * @return 연결된 개체
     */
    @Transactional
    public PetMst bind(Long userId, String tagCd, Long petId, boolean rebind) {
        NfcTagMst tag = findTag(tagCd);

        if (tag.isRevoked()) {
            throw new BusinessException(ErrorCode.TAG_REVOKED);
        }
        Long prevPetId = tag.getPetId();
        if (prevPetId != null && !prevPetId.equals(petId)) {
            assertRebindAllowed(userId, tag, rebind);
        }
        PetMst pet = petKeeperService.assertOwner(userId, petId);

        tag.linkTo(pet.getId(), userId);
        // 같은 개체에 다시 붙인 건 이력이 아니다 (스캔 후 무심코 재연결)
        if (!pet.getId().equals(prevPetId)) {
            bindHistoryRepository.save(
                    NfcTagBindHst.bound(tag.getTagCd(), pet.getId(), prevPetId, userId));
        }
        return pet;
    }

    /** 이미 연결된 태그를 옮겨도 되는지. 안 되면 여기서 예외로 끝난다 */
    private void assertRebindAllowed(Long userId, NfcTagMst tag, boolean rebind) {
        Optional<PetMst> current = petRepository.findById(tag.getPetId());
        if (current.isEmpty()) {
            return; // 붙어 있던 개체가 사라졌다 — 확인을 물을 대상 자체가 없다
        }
        if (!tag.isOwnedBy(userId)) {
            throw new BusinessException(ErrorCode.TAG_ALREADY_LINKED);
        }
        if (!rebind) {
            // 어느 개체에서 떼어내는지 알려줘야 사용자가 확인을 할 수 있다
            throw new BusinessException(ErrorCode.TAG_REBIND_CONFIRM_REQUIRED,
                    "이 태그는 '" + current.get().getName() + "'에 연결되어 있습니다. 옮길까요?");
        }
    }

    @Transactional
    public void unlink(Long userId, String tagCd) {
        NfcTagMst tag = findTag(tagCd);
        if (!tag.isOwnedBy(userId)) {
            throw new BusinessException(ErrorCode.TAG_ACCESS_DENIED);
        }
        Long prevPetId = tag.getPetId();
        tag.unlink();
        if (prevPetId != null) {
            bindHistoryRepository.save(NfcTagBindHst.unbound(tag.getTagCd(), prevPetId, userId));
        }
    }

    /** 태그 한 장의 연결 내역 (최신순) — 태그 소유자만. 분쟁 확인용 */
    public List<NfcTagBindHst> bindHistory(Long userId, String tagCd) {
        NfcTagMst tag = findTag(tagCd);
        if (!tag.isOwnedBy(userId)) {
            throw new BusinessException(ErrorCode.TAG_ACCESS_DENIED);
        }
        return bindHistoryRepository.findAllByTagCdOrderByIdDesc(tag.getTagCd());
    }

    // -------------------------------------------------------------------------
    // 재고 생산 (어드민)
    // -------------------------------------------------------------------------

    /**
     * 미연결 재고 태그 {@code count} 개 발급. 반환된 코드를 실물 칩에 굽는다.
     *
     * <p>{@code batchNo} 는 불량 회수 단위다. 한 번에 굽는 묶음마다 다른 값을 주면
     * 나중에 배치 단위로 통째로 차단할 수 있다.
     */
    @Transactional
    public List<String> issueStock(int count, String chipType, String batchNo) {
        List<NfcTagMst> tags = tagCodeGenerator.generateUnique(count).stream()
                .map(cd -> NfcTagMst.stock(cd, chipType, batchNo))
                .toList();
        tagRepository.saveAll(tags);
        return tags.stream().map(NfcTagMst::getTagCd).sorted().toList();
    }

    /**
     * 분실·복제 사고 태그 영구 차단. 연결도 함께 끊는다.
     * 되돌리는 API 는 두지 않는다 — 차단된 코드가 되살아나면 차단의 의미가 없다.
     */
    @Transactional
    public int revoke(List<String> tagCds) {
        return revokeAll(tagRepository.findAllById(
                tagCds.stream().map(NfcTagService::normalize).distinct().toList()));
    }

    /** 배치 단위 회수 — 불량 생산분을 통째로 차단 */
    @Transactional
    public int revokeBatch(String batchNo) {
        return revokeAll(tagRepository.findAllByBatchNo(batchNo));
    }

    /** 차단은 연결을 끊는 행위이기도 하다 — 끊긴 사실을 이력에 남긴다 (actor 는 어드민이라 null) */
    private int revokeAll(List<NfcTagMst> tags) {
        for (NfcTagMst tag : tags) {
            Long prevPetId = tag.getPetId();
            tag.revoke();
            bindHistoryRepository.save(NfcTagBindHst.revoked(tag.getTagCd(), prevPetId, null));
        }
        return tags.size();
    }

    public Map<String, Long> stockStats() {
        return Map.of(
                "unsold",   tagRepository.countByStatus(TagStockStatus.STOCK),
                "linked",   tagRepository.countByStatus(TagStockStatus.BOUND),
                "released", tagRepository.countByStatus(TagStockStatus.SOLD),
                "revoked",  tagRepository.countByStatus(TagStockStatus.REVOKED));
    }

    // -------------------------------------------------------------------------

    private NfcTagMst findTag(String tagCd) {
        return tagRepository.findById(normalize(tagCd))
                .orElseThrow(() -> new BusinessException(ErrorCode.TAG_NOT_FOUND));
    }

    /** 태그 코드는 대문자 풀만 사용 — 소문자 URL 로 들어와도 받아준다 */
    private static String normalize(String tagCd) {
        return tagCd == null ? "" : tagCd.trim().toUpperCase();
    }
}
