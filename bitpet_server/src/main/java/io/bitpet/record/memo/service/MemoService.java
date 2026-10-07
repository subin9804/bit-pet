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
import io.bitpet.record.memo.dto.MemoResponse;
import io.bitpet.record.memo.dto.MemoTagResponse;
import io.bitpet.record.memo.dto.MemoUpdateRequest;
import io.bitpet.record.memo.dto.VetExtRequest;
import io.bitpet.record.memo.repository.MemoDtlRepository;
import io.bitpet.record.memo.repository.MemoTagCdRepository;
import io.bitpet.record.memo.repository.MemoTagRlsRepository;
import io.bitpet.record.memo.repository.MemoVetExtDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MemoService {

    private static final String VET_TAG = "VET";
    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    private final MemoDtlRepository memoRepo;
    private final MemoTagCdRepository tagCdRepo;
    private final MemoTagRlsRepository tagRlsRepo;
    private final MemoVetExtDtlRepository vetExtRepo;
    private final PetMstRepository petRepo;
    private final io.bitpet.pet.service.PetKeeperService petKeeper;
    private final JdbcTemplate jdbc;

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
                .createdByUserId(userId)
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

    /**
     * 기록 목록은 <b>페이지 없이 배열 그대로</b> 내린다. 필터(태그/기간)는 남긴다.
     *
     * ℹ️ 원래는 `Page` 로 잘라 `{items, totalElements}` 를 내려줬는데, 그 페이지는 **이미
     * 허구였다** — 아래에서 CUSTOM 루틴 합성 메모를 덧붙이고 다시 정렬하기 때문에
     * `totalElements` 가 페이지 로컬 개수였고, 실제로 페이지를 넘기면 중복·누락이 났다.
     * 합성분은 DB 에 없어 DB 페이징으로 셀 수가 없다. 그래서 고치는 방향이 아니라 버렸다.
     */
    public List<MemoResponse> getMemos(Long petId, Long userId,
                                       List<String> tagCodes,
                                       LocalDate from, LocalDate to) {
        loadOwnedPet(userId, petId);

        List<MemoDtl> rows;
        if (tagCodes != null && !tagCodes.isEmpty()) {
            rows = memoRepo.findByPetIdAndTagCodes(petId, tagCodes);
        } else if (from != null && to != null) {
            rows = memoRepo.findByPetIdAndPeriod(
                    petId,
                    from.atStartOfDay(SEOUL).toInstant(),
                    to.plusDays(1).atStartOfDay(SEOUL).toInstant().minusMillis(1));
        } else {
            rows = memoRepo.findAllByPetIdOrderByLoggedAtDesc(petId);
        }

        List<MemoResponse> items = new ArrayList<>(
                rows.stream().map(this::buildResponse).toList());


        items.sort(Comparator.comparing(MemoResponse::loggedAt).reversed());
        return items;
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
        memoRepo.delete(memo); // hard delete (자식은 위에서 정리 + DB CASCADE)
    }

    // -------------------------------------------------------------------------
    // private helpers
    // -------------------------------------------------------------------------


    private MemoResponse buildResponse(MemoDtl memo) {
        List<MemoTagRls> tagLinks = tagRlsRepo.findByMemoId(memo.getId());
        List<Long> tagIds = tagLinks.stream().map(MemoTagRls::getTagId).toList();
        List<MemoTagCd> tags = tagIds.isEmpty() ? List.of() : tagCdRepo.findAllById(tagIds);
        MemoVetExtDtl vetExt = vetExtRepo.findByMemoId(memo.getId()).orElse(null);
        return MemoResponse.of(memo, tags, vetExt, findRoutineTitle(memo.getRoutineId()));
    }

    /** 루틴發 메모의 루틴 제목 (soft delete된 루틴도 기록 표시를 위해 조회) */
    private String findRoutineTitle(Long routineId) {
        if (routineId == null) return null;
        List<String> titles = jdbc.query(
                "SELECT title FROM routine_mst WHERE id = ?",
                ps -> ps.setLong(1, routineId),
                (rs, i) -> rs.getString("title"));
        return titles.isEmpty() ? null : titles.get(0);
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
        // 공유 개체 포함 — 사육자(OWNER/KEEPER)면 메모 작성·조회 가능
        return petKeeper.assertKeeper(userId, petId);
    }

    private MemoDtl loadAccessibleMemo(Long memoId, Long userId) {
        MemoDtl memo = memoRepo.findById(memoId)
                .orElseThrow(() -> new BusinessException(ErrorCode.MEMO_NOT_FOUND));
        loadOwnedPet(userId, memo.getPetId());
        return memo;
    }
}
