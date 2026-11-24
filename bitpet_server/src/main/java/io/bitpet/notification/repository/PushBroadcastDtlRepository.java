package io.bitpet.notification.repository;

import io.bitpet.notification.domain.PushBroadcastDtl;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface PushBroadcastDtlRepository extends JpaRepository<PushBroadcastDtl, Long> {

    Page<PushBroadcastDtl> findAllByOrderByCreatedAtDesc(Pageable pageable);

    /** 공지 대상 — 탈퇴하지 않은 전원 */
    @Query(value = "SELECT id FROM user_mst WHERE deleted_at IS NULL ORDER BY id", nativeQuery = true)
    List<Long> findAllActiveUserIds();

    /**
     * 마케팅 대상 — MARKETING 동의의 <b>가장 최근 행</b>이 동의인 사람. 철회는 새 행으로 남으므로
     * "동의한 적 있음"으로 세면 철회한 사람에게 광고가 간다.
     *
     * <p>만 14세 미만은 뺀다 — 아동에게 광고 푸시를 보낼 이유가 없고, 동의가 남아 있어도 보수적으로 간다.
     */
    @Query(value = """
            SELECT a.user_id FROM (
                SELECT DISTINCT ON (user_id) user_id, agreed
                FROM user_agreement_dtl
                WHERE agreement_cd = 'MARKETING'
                ORDER BY user_id, agreed_at DESC, id DESC
            ) a
            JOIN user_mst u ON u.id = a.user_id AND u.deleted_at IS NULL
            WHERE a.agreed
              AND (u.birth_date IS NULL OR u.birth_date <= CURRENT_DATE - INTERVAL '14 years')
            ORDER BY a.user_id
            """, nativeQuery = true)
    List<Long> findMarketingConsentedUserIds();
}
