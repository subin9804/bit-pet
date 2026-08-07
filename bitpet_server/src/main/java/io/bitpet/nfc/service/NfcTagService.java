package io.bitpet.nfc.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.nfc.domain.NfcTagMst;
import io.bitpet.nfc.domain.TagStockStatus;
import io.bitpet.nfc.dto.MyTagResponse;
import io.bitpet.nfc.dto.TagResolveResponse;
import io.bitpet.nfc.repository.NfcTagMstRepository;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.service.PetKeeperService;
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
    private final PetMstRepository petRepository;
    private final PetKeeperService petKeeperService;
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
        // 개체가 소프트 삭제됐으면 미연결로 보여준다. 실제 연결 정리는 쓰기 경로(link)에서 한다
        Optional<PetMst> pet = petRepository.findById(tag.getPetId());
        if (pet.isEmpty()) {
            return TagResolveResponse.unlinked(tag.getTagCd());
        }
        return TagResolveResponse.linked(tag.getTagCd(), pet.get().getId(), pet.get().getName());
    }

    /** 미설치자 랜딩 페이지용 — 개체 이름만. 없거나 미연결이거나 차단됐으면 empty */
    public Optional<String> peekPetName(String tagCd) {
        return tagRepository.findById(normalize(tagCd))
                .filter(tag -> !tag.isRevoked())
                .map(NfcTagMst::getPetId)
                .flatMap(petRepository::findById)
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

    @Transactional
    public TagResolveResponse link(Long userId, String tagCd, Long petId) {
        NfcTagMst tag = findTag(tagCd);

        if (tag.isRevoked()) {
            throw new BusinessException(ErrorCode.TAG_REVOKED);
        }
        // 남이 쓰고 있는 태그는 가져올 수 없다 (원 소유자가 먼저 해제해야 함).
        // 단, 붙어 있던 개체가 이미 삭제됐다면 붙잡아 둘 이유가 없다 — 재사용 가능하게 푼다.
        if (tag.isLinked() && !tag.isOwnedBy(userId)) {
            if (petRepository.findById(tag.getPetId()).isPresent()) {
                throw new BusinessException(ErrorCode.TAG_ALREADY_LINKED);
            }
            tag.unlink();
        }
        // 개체 소유권 검증 — pet_mst.user_id 가 아니라 pet_keeper_rls 기준(OWNER만).
        // 이게 없으면 남의 개체에 내 태그를 붙일 수 있다.
        PetMst pet = petKeeperService.assertOwner(userId, petId);

        tag.linkTo(pet.getId(), userId);
        return TagResolveResponse.linked(tag.getTagCd(), pet.getId(), pet.getName());
    }

    @Transactional
    public void unlink(Long userId, String tagCd) {
        NfcTagMst tag = findTag(tagCd);
        if (!tag.isOwnedBy(userId)) {
            throw new BusinessException(ErrorCode.TAG_ACCESS_DENIED);
        }
        tag.unlink();
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
        List<NfcTagMst> tags = tagRepository.findAllById(
                tagCds.stream().map(NfcTagService::normalize).distinct().toList());
        tags.forEach(NfcTagMst::revoke);
        return tags.size();
    }

    /** 배치 단위 회수 — 불량 생산분을 통째로 차단 */
    @Transactional
    public int revokeBatch(String batchNo) {
        List<NfcTagMst> tags = tagRepository.findAllByBatchNo(batchNo);
        tags.forEach(NfcTagMst::revoke);
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
