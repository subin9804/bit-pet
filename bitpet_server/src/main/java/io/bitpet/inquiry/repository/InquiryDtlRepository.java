package io.bitpet.inquiry.repository;

import io.bitpet.inquiry.domain.InquiryCategory;
import io.bitpet.inquiry.domain.InquiryDtl;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;

public interface InquiryDtlRepository extends JpaRepository<InquiryDtl, Long> {

    long countByUserIdAndCreatedAtGreaterThanEqual(Long userId, Instant since);

    long countByUserId(Long userId);

    /** 관리 페이지 문의함 — 최근 것부터. category 가 null 이면 전체 */
    @Query("SELECT i FROM InquiryDtl i WHERE (:category IS NULL OR i.category = :category) ORDER BY i.createdAt DESC, i.id DESC")
    Page<InquiryDtl> findForAdmin(@Param("category") InquiryCategory category, Pageable pageable);

    @Modifying
    @Query("DELETE FROM InquiryDtl i WHERE i.userId = :userId")
    int deleteAllByUserId(@Param("userId") Long userId);
}
