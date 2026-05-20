package io.bitpet.common.entity;

import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;

import java.util.UUID;

@Getter
@MappedSuperclass
public abstract class BaseSyncEntity extends BaseTimeEntity {

    @Column(name = "sync_version", nullable = false, insertable = false, updatable = false)
    private long syncVersion;

    @Column(name = "client_id", length = 64)
    private String clientId;

    @Column(name = "client_change_id", columnDefinition = "uuid")
    private UUID clientChangeId;

    public void stampClientChange(String clientId, UUID clientChangeId) {
        this.clientId = clientId;
        this.clientChangeId = clientChangeId;
    }
}
