package io.bitpet.record.memo.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "memo_vet_ext_dtl",
        indexes = @Index(name = "idx_memo_vet_ext_next_visit", columnList = "next_visit_at")
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MemoVetExtDtl extends BaseTimeEntity {

    @Id
    @Column(name = "memo_id")
    private Long memoId;

    @Column(name = "clinic_name", length = 100)
    private String clinicName;

    @Column
    private Integer cost;

    @Column(name = "next_visit_at")
    private Instant nextVisitAt;

    @Builder
    private MemoVetExtDtl(Long memoId, String clinicName, Integer cost, Instant nextVisitAt) {
        this.memoId = memoId;
        this.clinicName = clinicName;
        this.cost = cost;
        this.nextVisitAt = nextVisitAt;
    }

    public void update(String clinicName, Integer cost, Instant nextVisitAt) {
        this.clinicName = clinicName;
        this.cost = cost;
        this.nextVisitAt = nextVisitAt;
    }
}
