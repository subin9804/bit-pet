package io.bitpet.record.memo.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.record.memo.domain.MemoDtl;
import io.bitpet.record.memo.domain.MemoTagCd;
import io.bitpet.record.memo.domain.MemoTagRls;
import io.bitpet.record.memo.domain.MemoVetExtDtl;
import io.bitpet.record.memo.dto.MemoCreateRequest;
import io.bitpet.record.memo.dto.MemoListResponse;
import io.bitpet.record.memo.dto.MemoResponse;
import io.bitpet.record.memo.dto.MemoTagResponse;
import io.bitpet.record.memo.dto.MemoUpdateRequest;
import io.bitpet.record.memo.dto.VetExtRequest;
import io.bitpet.record.memo.repository.MemoDtlRepository;
import io.bitpet.record.memo.repository.MemoTagCdRepository;
import io.bitpet.record.memo.repository.MemoTagRlsRepository;
import io.bitpet.record.memo.repository.MemoVetExtDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MemoService {

    private static final String VET_TAG = "VET";

    private final MemoDtlRepository memoRepo;
    private final MemoTagCdRepository tagCdRepo;
    private final MemoTagRlsRepository tagRlsRepo;
    private final MemoVetExtDtlRepository vetExtRepo;
    private final PetMstRepository petRepo;

    // -------------------------------------------------------------------------
    // 태그 목록
    // -------------------------------------------------------------------------

    public List<MemoTagResponse> getTagList() {
        return tagCdRepo.findByIsActiveTrueOrderByDisplayOrderAsc()
                .stream().map(MemoTagResponse::from).toList();
    }

    // -------------------------------------------------------------------------
    // 메모 생성
    // -------------------------------------------------------------------------

    @Transactional
    public MemoResponse createMemo(Long petId, Long userId, MemoCreateRequest req) {
        loadOwnedPet(userId, petId);

        List<String> tagCodes = req.tags() != null ? req.tags() : List.of();
        boolean hasVet = tagCodes.stream().anyMatch(VET_TAG::equalsIgnoreCase);

        if (hasVet && req.vetExt() == null) {
            throw new BusinessException(ErrorCode.MEMO_VET_EXT_REQUIRED);
        }

        List<MemoTagCd> resolvedTags = resolveTags(tagCodes);

        MemoDtl memo = memoRepo.save(MemoDtl.builder()
                .petId(petId)
                .content(req.content())
                .loggedAt(req.loggedAt().toInstant())
                .build());

        saveTags(memo.getId(), resolvedTags);

        MemoVetExtDtl vetExt = null;
        if (hasVet) {
            vetExt = saveVetExt(memo.getId(), req.vetExt());
        }

        return MemoResponse.of(memo, resolvedTags, vetExt);
    }

    // -------------------------------------------------------------------------
    // 메모 목록
    // -------------------------------------------------------------------------

    public MemoListResponse getMemos(Long petId, Long userId,
                                     List<String> tagCodes,
                                     LocalDate from, LocalDate to,
                                     Pageable pageable) {
        loadOwnedPet(userId, petId);

        Page<MemoDtl> page;
        if (tagCodes != null && !tagCodes.isEmpty()) {
            page = memoRepo.findByPetIdAndTagCodes(petId, tagCodes, pageable);
        } else if (from != null && to != null) {
            page = memoRepo.findByPetIdAndPeriod(
                    petId,
                    from.atStartOfDay().toInstant(ZoneOffset.UTC),
                    to.atTime(23, 59, 59).toInstant(ZoneOffset.UTC),
                    pageable);
        } else {
            page = memoRepo.findAllByPetIdOrderByLoggedAtDesc(petId, pageable);
        }

        List<MemoResponse> items = page.getContent().stream()
                .map(m -> buildResponse(m))
                .toList();

        return new MemoListResponse(items, page.getTotalElements());
    }

    // -------------------------------------------------------------------------
    // 메모 단건
    // -------------------------------------------------------------------------

    public MemoResponse getMemo(Long memoId, Long userId) {
        MemoDtl memo = loadAccessibleMemo(memoId, userId);
        return buildResponse(memo);
    }

    // -------------------------------------------------------------------------
    // 메모 수정 (PUT — 전체 교체)
    // -------------------------------------------------------------------------

    @Transactional
    public MemoResponse updateMemo(Long memoId, Long userId, MemoUpdateRequest req) {
        MemoDtl memo = loadAccessibleMemo(memoId, userId);

        List<String> tagCodes = req.tags() != null ? req.tags() : List.of();
        boolean hasVet = tagCodes.stream().anyMatch(VET_TAG::equalsIgnoreCase);

        if (hasVet && req.vetExt() == null) {
            throw new BusinessException(ErrorCode.MEMO_VET_EXT_REQUIRED);
        }

        List<MemoTagCd> resolvedTags = resolveTags(tagCodes);

        memo.update(req.content(), req.loggedAt().toInstant());

        // 태그 전체 교체
        tagRlsRepo.deleteByMemoId(memoId);
        saveTags(memoId, resolvedTags);

        // vetExt 처리
        MemoVetExtDtl vetExt;
        if (hasVet) {
            vetExt = vetExtRepo.findByMemoId(memoId)
                    .map(existing -> { existing.update(req.vetExt().clinicName(), req.vetExt().cost(),
                            req.vetExt().nextVisitAt() != null ? req.vetExt().nextVisitAt().toInstant() : null);
                        return existing; })
                    .orElseGet(() -> saveVetExt(memoId, req.vetExt()));
        } else {
            vetExtRepo.deleteByMemoId(memoId);
            vetExt = null;
        }

        return MemoResponse.of(memo, resolvedTags, vetExt);
    }

    // -------------------------------------------------------------------------
    // 메모 삭제
    // -------------------------------------------------------------------------

    @Transactional
    public void deleteMemo(Long memoId, Long userId) {
        MemoDtl memo = loadAccessibleMemo(memoId, userId);
        tagRlsRepo.deleteByMemoId(memoId);
        vetExtRepo.deleteByMemoId(memoId);
        memo.softDelete();
    }

    // -------------------------------------------------------------------------
    // private helpers
    // -------------------------------------------------------------------------

    private MemoResponse buildResponse(MemoDtl memo) {
        List<MemoTagRls> tagLinks = tagRlsRepo.findByMemoId(memo.getId());
        List<Long> tagIds = tagLinks.stream().map(MemoTagRls::getTagId).toList();
        List<MemoTagCd> tags = tagIds.isEmpty() ? List.of() : tagCdRepo.findAllById(tagIds);
        MemoVetExtDtl vetExt = vetExtRepo.findByMemoId(memo.getId()).orElse(null);
        return MemoResponse.of(memo, tags, vetExt);
    }

    private List<MemoTagCd> resolveTags(List<String> codes) {
        if (codes.isEmpty()) return List.of();
        List<MemoTagCd> found = tagCdRepo.findByCodeIn(codes);
        if (found.size() != codes.size()) {
            throw new BusinessException(ErrorCode.MEMO_TAG_INVALID);
        }
        return found;
    }

    private void saveTags(Long memoId, List<MemoTagCd> tags) {
        tags.forEach(tag -> tagRlsRepo.save(MemoTagRls.builder()
                .memoId(memoId).tagId(tag.getId()).build()));
    }

    private MemoVetExtDtl saveVetExt(Long memoId, VetExtRequest req) {
        return vetExtRepo.save(MemoVetExtDtl.builder()
                .memoId(memoId)
                .clinicName(req.clinicName())
                .cost(req.cost())
                .nextVisitAt(req.nextVisitAt() != null ? req.nextVisitAt().toInstant() : null)
                .build());
    }

    private PetMst loadOwnedPet(Long userId, Long petId) {
        PetMst pet = petRepo.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
        return pet;
    }

    private MemoDtl loadAccessibleMemo(Long memoId, Long userId) {
        MemoDtl memo = memoRepo.findById(memoId)
                .orElseThrow(() -> new BusinessException(ErrorCode.MEMO_NOT_FOUND));
        loadOwnedPet(userId, memo.getPetId());
        return memo;
    }
}
