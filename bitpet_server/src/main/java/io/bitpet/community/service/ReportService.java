package io.bitpet.community.service;

import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.community.domain.PostCommentDtl;
import io.bitpet.community.domain.PostMst;
import io.bitpet.community.domain.PostReportDtl;
import io.bitpet.community.domain.ReportReason;
import io.bitpet.community.domain.ReportStatus;
import io.bitpet.community.domain.ReportTargetType;
import io.bitpet.community.dto.ReportCreateRequest;
import io.bitpet.community.dto.ReportHandleRequest;
import io.bitpet.community.dto.ReportReasonResponse;
import io.bitpet.community.dto.ReportResponse;
import io.bitpet.community.repository.PostCommentDtlRepository;
import io.bitpet.community.repository.PostMstRepository;
import io.bitpet.community.repository.PostReportDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;

/**
 * 커뮤니티 신고.
 *
 * <p><b>신고하면 차단도 된다.</b> 신고한 글이 계속 눈앞에 보이면 신고한 의미가 없다.
 * 반대로 차단은 신고를 만들지 않는다 ({@link BlockService}) — 사용자가 고른 것만 한다.
 *
 * <p><b>신고는 취소되지 않는다.</b> 접수된 사건의 이력이라 지우면 "몇 번 신고당했는지"가
 * 사라진다. 마음이 바뀌면 차단만 해제하면 된다.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReportService {

    /** 운영자 큐에 붙일 본문 미리보기 길이 */
    private static final int PREVIEW_LENGTH = 80;

    private final PostReportDtlRepository reportRepository;
    private final PostMstRepository postRepository;
    private final PostCommentDtlRepository commentRepository;
    private final UserMstRepository userRepository;
    private final BlockService blockService;
    private final SuspensionService suspensionService;

    /** 신고 사유 목록 — 앱의 사유 선택 시트가 이걸 그린다 */
    public List<ReportReasonResponse> listReasons() {
        return Arrays.stream(ReportReason.values()).map(ReportReasonResponse::from).toList();
    }

    @Transactional
    public void report(Long reporterUserId, ReportCreateRequest req) {
        suspensionService.assertNotSuspended(reporterUserId);
        Long targetUserId = resolveTargetUserId(req.targetType(), req.targetId());

        if (reporterUserId.equals(targetUserId)) {
            throw new BusinessException(ErrorCode.REPORT_SELF);
        }
        if (reportRepository.existsByReporterUserIdAndTargetTypeAndTargetId(
                reporterUserId, req.targetType(), req.targetId())) {
            throw new BusinessException(ErrorCode.REPORT_DUPLICATE);
        }

        reportRepository.save(PostReportDtl.builder()
                .reporterUserId(reporterUserId)
                .targetType(req.targetType())
                .targetId(req.targetId())
                .targetUserId(targetUserId)
                .reasonCd(req.reasonCd())
                .detail(req.detail())
                .build());

        // 신고 → 차단 동반. 이미 차단한 상대면 block() 이 조용히 통과한다.
        blockService.block(reporterUserId, targetUserId);
    }

    // -------------------------------------------------------------------------
    // 운영자 큐
    // -------------------------------------------------------------------------

    /** status 가 null 이면 전체(최신순), 주어지면 해당 상태만 오래된 순 */
    public Page<ReportResponse> list(ReportStatus status, Pageable pageable) {
        Page<PostReportDtl> page = status == null
                ? reportRepository.findAllByOrderByCreatedAtDesc(pageable)
                : reportRepository.findByStatusOrderByCreatedAtAsc(status, pageable);
        return page.map(this::toResponse);
    }

    /**
     * 신고 처리.
     *
     * <p>조치는 신고 대상에 직접 적용된다. BLIND 는 내용을 지우지 않고 가리기만 하므로
     * 오판이어도 되돌릴 수 있고, DELETE 는 작성자 삭제와 같은 소프트 삭제다.
     */
    @Transactional
    public ReportResponse handle(Long adminUserId, Long reportId, ReportHandleRequest req) {
        PostReportDtl report = reportRepository.findById(reportId)
                .orElseThrow(() -> new BusinessException(ErrorCode.REPORT_NOT_FOUND));
        if (report.getStatus() != ReportStatus.PENDING) {
            throw new BusinessException(ErrorCode.REPORT_ALREADY_HANDLED);
        }

        applyAction(report, req, adminUserId);
        report.handle(req.status(), req.action(), adminUserId, req.memo());
        return toResponse(report);
    }

    private void applyAction(PostReportDtl report, ReportHandleRequest req, Long adminUserId) {
        switch (req.action()) {
            case NONE -> { /* 위반 아님 — 대상은 그대로 둔다 */ }
            case BLIND -> blindTarget(report, adminUserId);
            // USER 신고에는 가릴 '내용'이 없다 — 계정 조치는 SUSPEND 의 몫이다
            case DELETE -> {
                if (report.getTargetType() == ReportTargetType.POST) {
                    findPost(report.getTargetId()).softDelete();
                } else if (report.getTargetType() == ReportTargetType.COMMENT) {
                    findComment(report.getTargetId()).softDelete();
                }
            }
            // 정지(V5)는 작성자의 커뮤니티 쓰기를 막고, 신고된 글·댓글은 가린다 — 정지할 만큼의
            // 위반이면 그 내용이 계속 보일 이유가 없다. 가림이라 정지를 풀 때 운영자가 되돌릴 수 있다.
            case SUSPEND -> {
                if (req.status() != ReportStatus.RESOLVED) {
                    throw new BusinessException(ErrorCode.INVALID_INPUT, "정지는 위반 인정(RESOLVED)일 때만 할 수 있어요.");
                }
                blindTarget(report, adminUserId);
                suspensionService.suspend(report.getTargetUserId(), req.suspendDuration(),
                        report.getId(), req.memo(), adminUserId);
            }
        }
    }

    /** 가림 해제 — 오판 정정. 신고의 처리 상태·조치 기록은 그대로 둔다(무슨 일이 있었는지는 남아야 한다) */
    @Transactional
    public ReportResponse unblind(Long reportId) {
        PostReportDtl report = reportRepository.findById(reportId)
                .orElseThrow(() -> new BusinessException(ErrorCode.REPORT_NOT_FOUND));
        setTargetBlinded(report, false, null);
        return toResponse(report);
    }

    private void blindTarget(PostReportDtl report, Long adminUserId) {
        setTargetBlinded(report, true, adminUserId);
    }

    /**
     * 작성자가 이미 지운 글·댓글은 조용히 건너뛴다 — 신고 후 글을 지웠다고 정지를 못 하면
     * "지우면 그만"이 된다. 가릴 내용이 없을 뿐 계정 조치는 그대로 간다.
     */
    private void setTargetBlinded(PostReportDtl report, boolean blinded, Long adminUserId) {
        if (report.getTargetType() == ReportTargetType.POST) {
            postRepository.findById(report.getTargetId()).ifPresent(p -> p.setBlinded(blinded, adminUserId));
        } else if (report.getTargetType() == ReportTargetType.COMMENT) {
            commentRepository.findById(report.getTargetId()).ifPresent(c -> c.setBlinded(blinded, adminUserId));
        }
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /**
     * 신고 대상의 작성자.
     *
     * <p>{@code post_report_dtl.target_user_id} 에 비정규화해 저장하려고 여기서 미리 푼다 —
     * 글이 지워진 뒤에도 누구를 신고한 것인지는 남아야 운영자가 판단할 수 있다.
     */
    private Long resolveTargetUserId(ReportTargetType type, Long targetId) {
        return switch (type) {
            case POST    -> findPost(targetId).getUserId();
            case COMMENT -> findComment(targetId).getUserId();
            case USER    -> {
                if (!userRepository.existsById(targetId)) {
                    throw new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND);
                }
                yield targetId;
            }
        };
    }

    private PostMst findPost(Long postId) {
        return postRepository.findById(postId)
                .orElseThrow(() -> new BusinessException(ErrorCode.POST_NOT_FOUND));
    }

    private PostCommentDtl findComment(Long commentId) {
        return commentRepository.findById(commentId)
                .orElseThrow(() -> new BusinessException(ErrorCode.COMMENT_NOT_FOUND));
    }

    private ReportResponse toResponse(PostReportDtl r) {
        String nickname = userRepository.findById(r.getTargetUserId())
                .map(UserMst::getName).orElse("알 수 없음");
        long count = reportRepository.countByTargetTypeAndTargetId(r.getTargetType(), r.getTargetId());

        String preview = null;
        boolean blinded = false;
        if (r.getTargetType() == ReportTargetType.POST) {
            PostMst post = postRepository.findById(r.getTargetId()).orElse(null);
            if (post != null) {
                preview = truncate(post.getTitle() + " — " + post.getContent());
                blinded = post.isBlinded();
            }
        } else if (r.getTargetType() == ReportTargetType.COMMENT) {
            PostCommentDtl comment = commentRepository.findById(r.getTargetId()).orElse(null);
            if (comment != null) {
                preview = truncate(comment.getContent());
                blinded = comment.isBlinded();
            }
        }
        return ReportResponse.of(r, nickname, preview, blinded, count);
    }

    private static String truncate(String s) {
        if (s == null) return null;
        String flat = s.replaceAll("\\s+", " ").trim();
        return flat.length() <= PREVIEW_LENGTH ? flat : flat.substring(0, PREVIEW_LENGTH) + "…";
    }
}
