package io.bitpet.pet.domain;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Getter
@Table(
        name = "pet_morph_rls",
        indexes = @Index(name = "idx_pet_morph_rls_morph_id", columnList = "morph_id, pet_id"),
        uniqueConstraints = @UniqueConstraint(
                name = "uq_pet_morph_rls_client",
                columnNames = {"client_id", "client_change_id"})
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PetMorphRls {

    @EmbeddedId
    private PetMorphRlsId id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId("petId")
    @JoinColumn(name = "pet_id",
            foreignKey = @jakarta.persistence.ForeignKey(name = "fk_pet_morph_rls_pet"))
    private PetMst pet;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId("morphId")
    @JoinColumn(name = "morph_id",
            foreignKey = @jakarta.persistence.ForeignKey(name = "fk_pet_morph_rls_morph"))
    private MorphCd morph;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "sync_version", nullable = false, insertable = false, updatable = false)
    private long syncVersion;

    @Column(name = "client_id", length = 64)
    private String clientId;

    @Column(name = "client_change_id", columnDefinition = "uuid")
    private UUID clientChangeId;

    public static PetMorphRls of(PetMst pet, MorphCd morph) {
        PetMorphRls rls = new PetMorphRls();
        rls.id = new PetMorphRlsId(pet.getId(), morph.getId());
        rls.pet = pet;
        rls.morph = morph;
        return rls;
    }

    public void stampClientChange(String clientId, UUID clientChangeId) {
        this.clientId = clientId;
        this.clientChangeId = clientChangeId;
    }
}
