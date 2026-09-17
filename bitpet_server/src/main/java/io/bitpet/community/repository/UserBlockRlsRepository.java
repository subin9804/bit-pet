package io.bitpet.community.repository;

import io.bitpet.community.domain.UserBlockRls;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserBlockRlsRepository extends JpaRepository<UserBlockRls, Long> {

    Optional<UserBlockRls> findByBlockerUserIdAndBlockedUserId(Long blockerUserId, Long blockedUserId);

    boolean existsByBlockerUserIdAndBlockedUserId(Long blockerUserId, Long blockedUserId);

    /** 차단 목록 화면용 — 내가 차단한 사람만. 나를 차단한 사람은 절대 내려주지 않는다 */
    List<UserBlockRls> findByBlockerUserIdOrderByCreatedAtDesc(Long blockerUserId);

    /**
     * 나와 차단 관계에 있는 모든 상대 — <b>양방향</b>.
     *
     * <p>내가 차단한 사람뿐 아니라 <b>나를 차단한 사람</b>도 함께 가린다. 단방향으로만 가리면
     * 차단당한 쪽이 상대 글에 계속 댓글을 달 수 있어 차단이 괴롭힘을 막지 못한다.
     * 그러면서도 "차단당했다"는 사실은 어디에도 알리지 않는다 — 그냥 목록에서 사라질 뿐이다.
     */
    @Query("SELECT CASE WHEN b.blockerUserId = :userId THEN b.blockedUserId ELSE b.blockerUserId END "
            + "FROM UserBlockRls b WHERE b.blockerUserId = :userId OR b.blockedUserId = :userId")
    List<Long> findRelatedUserIds(@Param("userId") Long userId);
}
