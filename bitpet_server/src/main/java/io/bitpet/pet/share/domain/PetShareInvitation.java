package io.bitpet.pet.share.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Entity
@Getter
@Table(
        name = "pet_share_invitation",
        indexes = {
                @Index(name = "idx_pet_share_inv_invitee", columnList = "invitee_user_id, status"),
                @Index(name = "idx_pet_share_inv_pet",     columnList = "pet_id, status"),
                @Index(name = "idx_pet_share_inv_batch",   columnList = "batch_id")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PetShareInvitation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Column(name = "inviter_user_id", nullable = false)
    private Long inviterUserId;

    @Column(name = "invitee_user_id", nullable = false)
    private Long inviteeUserId;

    /** 벌크 초대 그룹 식별자 (단건 초대도 고유 배치 1건) */
    @Column(name = "batch_id", nullable = false, updatable = false)
    private UUID batchId;

    @Enumerated(EnumType.STRING)
    @Column(name = "invite_type", nullable = false, length = 20)
    private ShareInviteType inviteType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ShareInviteStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "responded_at")
    private Instant respondedAt;

    /** 초대 유효 기간 (생성 시각 + 7일) */
    private static final Duration TTL = Duration.ofDays(7);

    @Builder
    private PetShareInvitation(Long petId, Long inviterUserId, Long inviteeUserId,
                               ShareInviteType inviteType, UUID batchId) {
        this.petId          = petId;
        this.inviterUserId  = inviterUserId;
        this.inviteeUserId  = inviteeUserId;
        this.inviteType     = inviteType;
        this.batchId        = batchId != null ? batchId : UUID.randomUUID();
        this.status         = ShareInviteStatus.PENDING;
        this.createdAt      = Instant.now();
        this.expiresAt      = this.createdAt.plus(TTL);
    }

    public void accept()  { this.status = ShareInviteStatus.ACCEPTED; this.respondedAt = Instant.now(); }
    public void reject()  { this.status = ShareInviteStatus.REJECTED; this.respondedAt = Instant.now(); }
    public void cancel()  { this.status = ShareInviteStatus.CANCELED; this.respondedAt = Instant.now(); }
    public void expire()  { this.status = ShareInviteStatus.EXPIRED;  this.respondedAt = Instant.now(); }

    public boolean isPending() { return status == ShareInviteStatus.PENDING; }

    /** 대기중이면서 만료 시각이 지났는지 */
    public boolean isExpired() {
        return status == ShareInviteStatus.PENDING && Instant.now().isAfter(expiresAt);
    }
}
