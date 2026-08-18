package io.bitpet.auth.repository;

import io.bitpet.auth.domain.UserAgreementDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserAgreementDtlRepository extends JpaRepository<UserAgreementDtl, Long> {

    /**
     * 유저의 전체 동의 이력을 최신순으로.
     *
     * <p>항목별 최신 행만 뽑는 SQL(윈도우 함수)을 쓰지 않는 이유 — 한 사람의 이력은
     * 항목 4개 × 변경 횟수라 많아야 수십 행이다. 자바에서 접는 편이 단순하고,
     * "이력 전체 보기"가 필요해질 때도 같은 쿼리를 쓴다.
     */
    List<UserAgreementDtl> findByUserIdOrderByAgreedAtDesc(Long userId);
}
