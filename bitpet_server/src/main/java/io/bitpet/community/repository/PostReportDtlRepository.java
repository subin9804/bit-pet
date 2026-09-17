package io.bitpet.community.repository;

import io.bitpet.community.domain.PostReportDtl;
import io.bitpet.community.domain.ReportStatus;
import io.bitpet.community.domain.ReportTargetType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PostReportDtlRepository extends JpaRepository<PostReportDtl, Long> {

    boolean existsByReporterUserIdAndTargetTypeAndTargetId(
            Long reporterUserId, ReportTargetType targetType, Long targetId);

    /** 운영자 큐 — 오래된 것부터. 먼저 들어온 신고가 먼저 처리돼야 한다 */
    Page<PostReportDtl> findByStatusOrderByCreatedAtAsc(ReportStatus status, Pageable pageable);

    Page<PostReportDtl> findAllByOrderByCreatedAtDesc(Pageable pageable);

    /** 같은 대상에 신고가 몇 건 쌓였는지 — 운영자 판단용. ⛔ 이 수로 자동 블라인드하지 말 것 */
    long countByTargetTypeAndTargetId(ReportTargetType targetType, Long targetId);
}
