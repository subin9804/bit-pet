package io.bitpet.pet.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Getter
@Table(name = "serial_pool_stat_mst")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SerialPoolStatMst extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "serial_length", nullable = false, unique = true)
    private int serialLength;

    @Column(name = "total_capacity", nullable = false)
    private long totalCapacity;

    @Column(name = "used_count", nullable = false)
    private long usedCount;

    @Column(name = "usage_rate", nullable = false, precision = 5, scale = 4)
    private BigDecimal usageRate;

    @Column(name = "is_current", nullable = false)
    private boolean current;

    @Column(name = "expanded_at")
    private Instant expandedAt;

    public void refresh(long usedCount, BigDecimal usageRate) {
        this.usedCount = usedCount;
        this.usageRate = usageRate;
    }

    public void markCurrent(boolean current) {
        this.current = current;
    }

    public void markExpanded() {
        this.expandedAt = Instant.now();
    }
}
