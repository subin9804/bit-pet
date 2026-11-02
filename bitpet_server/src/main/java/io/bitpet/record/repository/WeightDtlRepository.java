package io.bitpet.record.repository;

import io.bitpet.record.domain.WeightDtl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface WeightDtlRepository extends JpaRepository<WeightDtl, Long> {

    List<WeightDtl> findAllByPetIdOrderByMeasuredAtDesc(Long petId);

    /**
     * 여러 개체의 최신 체중을 한 번에 — 개체 목록용.
     * 전에는 개체마다 체중 기록 <b>전체</b>를 읽고 첫 행만 썼다 (개체 수 × 기록 수).
     * DISTINCT ON 이 idx_weight_dtl_pet_time (pet_id, measured_at DESC) 를 그대로 탄다.
     * 네이티브라 @SQLRestriction 이 안 붙는다 — deleted_at 조건을 직접 건다.
     */
    @org.springframework.data.jpa.repository.Query(value = """
            SELECT DISTINCT ON (pet_id) pet_id AS petId, weight_g AS weightG
              FROM weight_dtl
             WHERE pet_id IN (:petIds) AND deleted_at IS NULL
             ORDER BY pet_id, measured_at DESC, id DESC
            """, nativeQuery = true)
    List<LatestWeightRow> findLatestByPetIds(
            @org.springframework.data.repository.query.Param("petIds") Collection<Long> petIds);

    interface LatestWeightRow {
        Long getPetId();
        java.math.BigDecimal getWeightG();
    }

    List<WeightDtl> findAllByPetIdInOrderByMeasuredAtDesc(Collection<Long> petIds, Pageable pageable);

    /** 하루치 조회 — 반열린 구간 [from, to). 양끝 포함 `Between` 은 다음날 00:00 기록을 전날에도 잡는다. */
    @org.springframework.data.jpa.repository.Query("""
            SELECT x FROM WeightDtl x
            WHERE x.petId IN :petIds AND x.measuredAt >= :from AND x.measuredAt < :to
            ORDER BY x.measuredAt DESC
            """)
    List<WeightDtl> findDay(
            @org.springframework.data.repository.query.Param("petIds") Collection<Long> petIds,
            @org.springframework.data.repository.query.Param("from") java.time.Instant from,
            @org.springframework.data.repository.query.Param("to") java.time.Instant to);

    /** 루틴 완료 로그에 연결된 체중 기록 (짝 정리·재로딩용) */
    List<WeightDtl> findByRoutineLogId(Long routineLogId);

    List<WeightDtl> findByRoutineLogIdIn(Collection<Long> routineLogIds);

    Optional<WeightDtl> findByClientIdAndClientChangeId(String clientId, UUID clientChangeId);
}
