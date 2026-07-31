package io.bitpet.nfc.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.nfc.domain.NfcTagMst;
import io.bitpet.nfc.domain.TagActionCd;
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
     * 태그 스캔 — 스캔 카운트를 올리고 상태를 판정한다.
     * 존재하지 않는 코드는 404 (위조 태그 차단).
     */
    @Transactional
    public TagResolveResponse resolve(Long userId, String tagCd) {
        NfcTagMst tag = findTag(tagCd);
        tag.markScanned();

        if (!tag.isLinked()) {
            return TagResolveResponse.unlinked(tag.getTagCd());
        }
        if (!petKeeperService.isKeeper(userId, tag.getPetId())) {
            return TagResolveResponse.ownedByOther(tag.getTagCd());
        }
        // 개체가 소프트 삭제됐으면 태그는 미연결로 되돌려 재사용할 수 있게 한다
        Optional<PetMst> pet = petRepository.findById(tag.getPetId());
        if (pet.isEmpty()) {
            tag.unlink();
            return TagResolveResponse.unlinked(tag.getTagCd());
        }
        return TagResolveResponse.linked(
                tag.getTagCd(), pet.get().getId(), pet.get().getName(), tag.getDefaultActionCd());
    }

    /** 미설치자 랜딩 페이지용 — 개체 이름만. 없거나 미연결이면 empty */
    @Transactional
    public Optional<String> peekPetName(String tagCd) {
        return tagRepository.findById(normalize(tagCd))
                .map(tag -> {
                    tag.markScanned();
                    return tag.getPetId();
                })
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
                        t.getDefaultActionCd(),
                        t.getLinkedAt(),
                        t.getScanCnt(),
                        t.getLastScanAt()))
                .toList();
    }

    // -------------------------------------------------------------------------
    // 연결 / 해제
    // -------------------------------------------------------------------------

    @Transactional
    public TagResolveResponse link(Long userId, String tagCd, Long petId, TagActionCd actionCd) {
        NfcTagMst tag = findTag(tagCd);

        // 남이 쓰고 있는 태그는 가져올 수 없다 (원 소유자가 먼저 해제해야 함)
        if (tag.isLinked() && !tag.isOwnedBy(userId)) {
            throw new BusinessException(ErrorCode.TAG_ALREADY_LINKED);
        }
        PetMst pet = petKeeperService.assertOwner(userId, petId);

        tag.linkTo(pet.getId(), userId, actionCd);
        return TagResolveResponse.linked(
                tag.getTagCd(), pet.getId(), pet.getName(), tag.getDefaultActionCd());
    }

    @Transactional
    public void unlink(Long userId, String tagCd) {
        NfcTagMst tag = findTag(tagCd);
        if (!tag.isOwnedBy(userId)) {
            throw new BusinessException(ErrorCode.TAG_ACCESS_DENIED);
        }
        tag.unlink();
    }

    /** 기본 동작만 변경 (개체는 그대로) */
    @Transactional
    public MyTagResponse updateAction(Long userId, String tagCd, TagActionCd actionCd) {
        NfcTagMst tag = findTag(tagCd);
        if (!tag.isOwnedBy(userId)) {
            throw new BusinessException(ErrorCode.TAG_ACCESS_DENIED);
        }
        tag.updateAction(actionCd);
        String petNm = petRepository.findById(tag.getPetId()).map(PetMst::getName).orElse(null);
        return new MyTagResponse(tag.getTagCd(), tag.getPetId(), petNm,
                tag.getDefaultActionCd(), tag.getLinkedAt(), tag.getScanCnt(), tag.getLastScanAt());
    }

    // -------------------------------------------------------------------------
    // 재고 생산 (어드민)
    // -------------------------------------------------------------------------

    /** 미연결 재고 태그 {@code count} 개 발급. 반환된 코드를 NTAG213 에 굽는다. */
    @Transactional
    public List<String> issueStock(int count) {
        List<NfcTagMst> tags = tagCodeGenerator.generateUnique(count).stream()
                .map(NfcTagMst::stock)
                .toList();
        tagRepository.saveAll(tags);
        return tags.stream().map(NfcTagMst::getTagCd).sorted().toList();
    }

    public Map<String, Long> stockStats() {
        return Map.of(
                "unsold",   tagRepository.countUnsoldStock(),
                "linked",   tagRepository.countLinked(),
                "released", tagRepository.countReleased());
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
