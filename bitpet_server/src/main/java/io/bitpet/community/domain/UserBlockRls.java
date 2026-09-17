package io.bitpet.community.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 사용자 차단.
 *
 * <p><b>행은 단방향이다.</b> {@code blocker} 가 {@code blocked} 를 차단한 사실 하나만 담는다.
 * 다만 이 행을 해석하는 방식은 두 가지다 —
 * <ul>
 *   <li><b>글 노출</b>: 차단한 쪽에서만 안 보인다. 양방향으로 숨기면 "차단" 이 아니라
 *       상대에게서 나를 지우는 도구가 되어, 시비를 걸고 차단해 도망가는 데 쓰인다.</li>
 *   <li><b>댓글</b>: 양방향으로 막는다. 단방향이면 차단해도 상대가 내 글에 계속 댓글을 달 수 있어
 *       정작 차단이 해결해 주는 게 없다.</li>
 * </ul>
 *
 * <p>⛔ 차단당한 사실을 상대에게 알리지 말 것. 알림이 가는 순간 보복이 시작된다.
 */
@Entity
@Getter
@Table(
        name = "user_block_rls",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_user_block_rls",
                        columnNames = {"blocker_user_id", "blocked_user_id"})
        },
        indexes = {
                @Index(name = "idx_user_block_rls_blocker", columnList = "blocker_user_id"),
                @Index(name = "idx_user_block_rls_blocked", columnList = "blocked_user_id")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserBlockRls extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "blocker_user_id", nullable = false)
    private Long blockerUserId;

    @Column(name = "blocked_user_id", nullable = false)
    private Long blockedUserId;

    @Builder
    private UserBlockRls(Long blockerUserId, Long blockedUserId) {
        this.blockerUserId = blockerUserId;
        this.blockedUserId = blockedUserId;
    }
}
