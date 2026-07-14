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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
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

    private final MemoDtlRepository memoRepo;
    private final MemoTagCdRepository tagCdRepo;
    private final MemoTagRlsRepository tagRlsRepo;
    private final MemoVetExtDtlRepository vetExtRepo;
    private final PetMstRepository petRepo;
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

        List<MemoResponse> items = new ArrayList<>(
                page.getContent().stream().map(this::buildResponse).toList());

        // 태그 필터 없을 때만 CUSTOM 루틴 메모 추가
        if (tagCodes == null || tagCodes.isEmpty()) {
            items.addAll(fetchCustomRoutineMemos(petId, from, to));
        }

        items.sort(Comparator.comparing(MemoResponse::loggedAt).reversed());
        return new MemoListResponse(items, (long) items.size());
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

    private List<MemoResponse> fetchCustomRoutineMemos(Long petId, LocalDate from, LocalDate to) {
        // CUSTOM 루틴 '완료' 로그를 메모로 집계.
        // 완료 시 메모를 남기면 같은 시각의 memo_dtl이 생성되므로(이중 표시 방지)
        // 대응하는 memo_dtl이 없는 로그만 포함한다.
        String sql = """
                SELECT rl.id, rl.pet_id, rl.memo, rl.executed_at, rl.created_at,
                       COALESCE(rm.title, '루틴') AS title
                FROM routine_log_dtl rl
                JOIN routine_mst rm ON rm.id = rl.routine_id
                WHERE rl.pet_id = ?
                  AND rm.routine_type = 'CUSTOM'
                  AND rl.status = 'COMPLETED'
                  AND rl.deleted_at IS NULL
                  AND NOT EXISTS (
                      SELECT 1 FROM memo_dtl m
                      WHERE m.routine_id = rl.routine_id AND m.pet_id = rl.pet_id
                        AND m.logged_at = rl.executed_at AND m.deleted_at IS NULL)
                ORDER BY rl.executed_at DESC
                """;
        return jdbc.query(sql, ps -> ps.setLong(1, petId), (rs, i) -> {
            Instant loggedAt = rs.getTimestamp("executed_at").toInstant();
            if (from != null && loggedAt.isBefore(from.atStartOfDay().toInstant(ZoneOffset.UTC))) return null;
            if (to   != null && loggedAt.isAfter(to.atTime(23, 59, 59).toInstant(ZoneOffset.UTC))) return null;
            Instant createdAt = rs.getTimestamp("created_at").toInstant();
            String memo = rs.getString("memo");
            String title = rs.getString("title");
            // 메모 있으면 "[루틴제목] 메모", 없으면 "[루틴제목] 완료"
            String content = (memo != null && !memo.isBlank())
                    ? "[" + title + "] " + memo
                    : "[" + title + "] 완료";
            return new MemoResponse(rs.getLong("id"), rs.getLong("pet_id"),
                    content, loggedAt, List.of(), null, null, createdAt, createdAt);
        }).stream().filter(m -> m != null).toList();
    }

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
