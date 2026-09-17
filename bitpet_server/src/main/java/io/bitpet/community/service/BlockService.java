package io.bitpet.community.service;

import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.community.domain.UserBlockRls;
import io.bitpet.community.dto.BlockedUserResponse;
import io.bitpet.community.repository.UserBlockRlsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 사용자 차단.
 *
 * <p><b>차단은 차단만 한다.</b> 신고와 달리 운영자에게 아무것도 올라가지 않는다 —
 * "이 사람 글이 내 눈에 안 보이면 좋겠다"는 것과 "규칙을 어겼으니 조치해달라"는 것은 다른 요청이다.
 * 반대로 신고는 차단을 함께 만든다 ({@link ReportService}).
 *
 * <p>⛔ <b>차단 사실을 상대에게 알리지 말 것.</b> 알림도, 에러 메시지의 구분도 없다.
 * 차단당한 쪽이 알게 되면 그게 곧 보복의 신호가 된다.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BlockService {

    private final UserBlockRlsRepository blockRepository;
    private final UserMstRepository userRepository;

    /** 차단. 이미 차단한 상대면 조용히 통과한다 (연타·재시도가 409 를 뱉을 이유가 없다) */
    @Transactional
    public void block(Long blockerUserId, Long blockedUserId) {
        if (blockerUserId.equals(blockedUserId)) {
            throw new BusinessException(ErrorCode.BLOCK_SELF);
        }
        if (!userRepository.existsById(blockedUserId)) {
            throw new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND);
        }
        if (blockRepository.existsByBlockerUserIdAndBlockedUserId(blockerUserId, blockedUserId)) {
            return;
        }
        blockRepository.save(UserBlockRls.builder()
                .blockerUserId(blockerUserId)
                .blockedUserId(blockedUserId)
                .build());
    }

    /**
     * 차단 해제.
     *
     * <p>신고와 달리 <b>해제할 수 있다</b>. 차단은 내 화면의 설정이지 사건의 이력이 아니다.
     * 신고했다가 마음이 바뀐 사용자도 여기로 온다 (신고 자체는 남는다).
     */
    @Transactional
    public void unblock(Long blockerUserId, Long blockedUserId) {
        UserBlockRls block = blockRepository
                .findByBlockerUserIdAndBlockedUserId(blockerUserId, blockedUserId)
                .orElseThrow(() -> new BusinessException(ErrorCode.BLOCK_NOT_FOUND));
        blockRepository.delete(block);
    }

    /** 차단 목록. 내가 차단한 사람만 — 나를 차단한 사람은 여기 뜨지 않는다 */
    public List<BlockedUserResponse> listBlocked(Long blockerUserId) {
        List<UserBlockRls> blocks = blockRepository.findByBlockerUserIdOrderByCreatedAtDesc(blockerUserId);
        if (blocks.isEmpty()) return List.of();

        Map<Long, UserMst> users = userRepository
                .findAllById(blocks.stream().map(UserBlockRls::getBlockedUserId).toList())
                .stream().collect(Collectors.toMap(UserMst::getId, u -> u));

        return blocks.stream().map(b -> {
            UserMst u = users.get(b.getBlockedUserId());
            return new BlockedUserResponse(
                    b.getBlockedUserId(),
                    u != null ? u.getName() : "알 수 없음",
                    u != null ? u.getProfileImageUrl() : null,
                    b.getCreatedAt());
        }).toList();
    }

    /**
     * 커뮤니티 조회에서 가려야 할 사용자 — 양방향.
     *
     * <p>목록 쿼리에 그대로 넘겨 쓰라고 {@code Set} 으로 돌려준다.
     * ⚠️ JPQL {@code NOT IN (:list)} 는 빈 리스트에서 터지므로, 부르는 쪽은 비었을 때
     * 필터 없는 쿼리로 분기하거나 센티넬을 넣어야 한다.
     */
    public Set<Long> hiddenUserIds(Long userId) {
        return Set.copyOf(blockRepository.findRelatedUserIds(userId));
    }

    /** 이 사람과 나 사이에 차단이 있는가 (어느 방향이든) */
    public boolean isHidden(Long userId, Long otherUserId) {
        if (userId == null || otherUserId == null || userId.equals(otherUserId)) return false;
        return blockRepository.existsByBlockerUserIdAndBlockedUserId(userId, otherUserId)
                || blockRepository.existsByBlockerUserIdAndBlockedUserId(otherUserId, userId);
    }
}
