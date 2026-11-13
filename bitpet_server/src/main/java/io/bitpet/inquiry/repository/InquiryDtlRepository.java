package io.bitpet.inquiry.repository;

import io.bitpet.inquiry.domain.InquiryDtl;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;

public interface InquiryDtlRepository extends JpaRepository<InquiryDtl, Long> {

    long countByUserIdAndCreatedAtGreaterThanEqual(Long userId, Instant since);

    long countByUserId(Long userId);

    @Modifying
    @Query("DELETE FROM InquiryDtl i WHERE i.userId = :userId")
    int deleteAllByUserId(@Param("userId") Long userId);
}
