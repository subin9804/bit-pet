package io.bitpet.record.memo.domain;

import io.bitpet.common.entity.BaseSyncEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.SQLRestriction;

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "memo_dtl",
        indexes = @Index(name = "idx_memo_dtl_pet_time", columnList = "pet_id, logged_at")
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MemoDtl extends BaseSyncEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    @Column(name = "logged_at", nullable = false)
    private Instant loggedAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private MemoDtl(Long petId, String content, Instant loggedAt) {
        this.petId = petId;
        this.content = content;
        this.loggedAt = loggedAt;
    }

    public void update(String content, Instant loggedAt) {
        if (content != null)   this.content = content;
        if (loggedAt != null)  this.loggedAt = loggedAt;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}
