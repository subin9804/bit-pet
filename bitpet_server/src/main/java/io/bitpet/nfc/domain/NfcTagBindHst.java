package io.bitpet.nfc.domain;

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
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

/**
 * NFC 태그 연결 이력 (append-only).
 *
 * <p>{@link NfcTagMst} 는 현재 상태만 들고 있어 재연결 때마다 이전 연결이 사라진다.
 * 실물 태그는 개체 양도·중고 거래·분실로 손을 옮겨 다니고, "내 태그를 가로챘다"는
 * 신고가 들어오면 현재 상태만으로는 판정할 수 없다 — 그래서 별도 이력을 남긴다.
 *
 * <p><b>수정·삭제 메서드를 두지 않는다.</b> 고쳐 쓸 수 있는 이력은 증거가 아니다.
 */
@Entity
@Getter
@Table(
        name = "nfc_tag_bind_hst",
        // 실제 인덱스는 V55 에 (tag_cd, id DESC) 로 만든다. 여기 정렬 방향은 적지 않는다 —
        // ddl-auto=validate 는 인덱스를 검사하지 않으므로 이 선언은 문서 역할만 한다
        indexes = @Index(name = "idx_nfc_tag_bind_hst_tag", columnList = "tag_cd, id")
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class NfcTagBindHst {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tag_cd", nullable = false, length = 10, updatable = false)
    private String tagCd;

    @Enumerated(EnumType.STRING)
    @Column(name = "action", nullable = false, length = 20, updatable = false)
    private TagBindAction action;

    /** 이 액션 이후의 연결 대상. UNBIND/REVOKE 면 null */
    @Column(name = "pet_id", updatable = false)
    private Long petId;

    /** 이 액션 직전의 연결 대상. 최초 BIND 면 null */
    @Column(name = "prev_pet_id", updatable = false)
    private Long prevPetId;

    /** 액션 주체. 어드민 차단·탈퇴 정리처럼 사용자 행위가 아니면 null */
    @Column(name = "actor_id", updatable = false)
    private Long actorId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    private NfcTagBindHst(String tagCd, TagBindAction action, Long petId, Long prevPetId, Long actorId) {
        this.tagCd = tagCd;
        this.action = action;
        this.petId = petId;
        this.prevPetId = prevPetId;
        this.actorId = actorId;
    }

    /**
     * 연결 이력 한 줄. {@code prevPetId} 유무로 BIND / REBIND 를 스스로 가른다 —
     * 호출부가 매번 판정하면 언젠가 한 곳이 틀린다.
     */
    public static NfcTagBindHst bound(String tagCd, Long petId, Long prevPetId, Long actorId) {
        TagBindAction action = prevPetId == null ? TagBindAction.BIND : TagBindAction.REBIND;
        return new NfcTagBindHst(tagCd, action, petId, prevPetId, actorId);
    }

    public static NfcTagBindHst unbound(String tagCd, Long prevPetId, Long actorId) {
        return new NfcTagBindHst(tagCd, TagBindAction.UNBIND, null, prevPetId, actorId);
    }

    public static NfcTagBindHst revoked(String tagCd, Long prevPetId, Long actorId) {
        return new NfcTagBindHst(tagCd, TagBindAction.REVOKE, null, prevPetId, actorId);
    }
}
