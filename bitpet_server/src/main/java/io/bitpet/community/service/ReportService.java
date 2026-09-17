package io.bitpet.community.service;

import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.community.domain.PostCommentDtl;
import io.bitpet.community.domain.PostMst;
import io.bitpet.community.domain.PostReportDtl;
import io.bitpet.community.domain.ReportAction;
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

    /** 신고 사유 목록 — 앱의 사유 선택 시트가 이걸 그린다 */
    public List<ReportReasonResponse> listReasons() {
        return Arrays.stream(ReportReason.values()).map(ReportReasonResponse::from).toList();
    }

    @Transactional
    public void report(Long reporterUserId, ReportCreateRequest req) {
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

        applyAction(report, req.action(), adminUserId);
        report.handle(req.status(), req.action(), adminUserId, req.memo());
        return toResponse(report);
    }

    private void applyAction(PostReportDtl report, ReportAction action, Long adminUserId) {
        switch (action) {
            case NONE -> { /* 위반 아님 — 대상은 그대로 둔다 */ }
            case BLIND -> {
                if (report.getTargetType() == ReportTargetType.POST) {
                    findPost(report.getTargetId()).setBlinded(true, adminUserId);
                } else if (report.getTargetType() == ReportTargetType.COMMENT) {
                    findComment(report.getTargetId()).setBlinded(true, adminUserId);
                }
                // USER 신고에는 가릴 '내용'이 없다 — 계정 조치는 SUSPEND 의 몫이다
            }
            case DELETE -> {
                if (report.getTargetType() == ReportTargetType.POST) {
                    findPost(report.getTargetId()).softDelete();
                } else if (report.getTargetType() == ReportTargetType.COMMENT) {
                    findComment(report.getTargetId()).softDelete();
                }
            }
            // 계정 일시정지는 2단계다. enum 에는 자리를 만들어 뒀지만 정지 상태를 들고 있을 곳이
            // 아직 없어서, 조용히 아무것도 안 하는 대신 명시적으로 거부한다.
            case SUSPEND -> throw new BusinessException(
                    ErrorCode.INVALID_INPUT, "계정 정지는 아직 지원하지 않습니다.");
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
