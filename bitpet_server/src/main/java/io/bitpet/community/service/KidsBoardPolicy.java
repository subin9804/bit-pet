package io.bitpet.community.service;

import io.bitpet.auth.domain.AdminRole;
import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.auth.service.AdminGuard;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.community.domain.PostCategoryCd;
import io.bitpet.community.repository.PostCategoryCdRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 어린이 게시판(KIDS) 접근 규칙 (V12).
 *
 * <p>규칙은 두 방향이고, 둘 다 있어야 의미가 있다.
 * <ul>
 *   <li><b>아동은 어린이 게시판에서만 쓴다.</b> 일반 게시판은 읽을 수 있지만 글·댓글·좋아요를
 *       남기지 못한다 — 흔적이 남는 순간 성인이 그 아이에게 말을 걸 경로가 생긴다.</li>
 *   <li><b>성인은 어린이 게시판을 읽지도 못한다.</b> ⛔ "읽기만 되게" 로 완화하지 말 것 —
 *       아동만 모인 공간이 성인에게 열려 있으면 그 자체가 아동에게 접근하는 통로다.</li>
 * </ul>
 *
 * <p>예외는 운영자(SUPER_ADMIN/MODERATOR)의 <b>읽기</b>뿐이다. 신고를 처리하려면 원문을 봐야
 * 한다. 운영자도 <b>쓰지는 못한다</b> — 어린이 게시판의 글쓴이는 전원 아동이라는 성질이
 * 이 게시판을 안전하게 만드는 전부이고, 예외를 하나라도 두면 그 전제가 깨진다.
 *
 * <p>판정 기준은 {@code post_category_cd.code == 'KIDS'} 다. ⛔ id(6)로 박지 말 것 —
 * DB 마다 갈릴 수 있어 "개발에선 되는데 운영에선 성인이 어린이 게시판을 본다"가 된다.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class KidsBoardPolicy {

    public static final String KIDS_CATEGORY_CODE = "KIDS";

    private final UserMstRepository userRepository;
    private final PostCategoryCdRepository categoryRepository;
    private final AdminGuard adminGuard;

    public boolean isChild(Long userId) {
        return userId != null && userRepository.findById(userId)
                .map(UserMst::isChild)
                .orElse(false);
    }

    public boolean isKidsCategory(Long categoryId) {
        return categoryId != null && categoryRepository.findById(categoryId)
                .map(c -> KIDS_CATEGORY_CODE.equals(c.getCode()))
                .orElse(false);
    }

    /**
     * 글·댓글·좋아요를 남길 수 있는가.
     *
     * <p>두 방향을 한 메서드에서 본다 — 나눠두면 호출부가 한쪽만 부르고 다른 쪽을 빠뜨린다.
     */
    public void assertCanWrite(Long userId, Long categoryId) {
        boolean kids = isKidsCategory(categoryId);
        boolean child = isChild(userId);

        if (child && !kids) {
            throw new BusinessException(ErrorCode.CHILD_BOARD_ONLY);
        }
        if (!child && kids) {
            throw new BusinessException(ErrorCode.KIDS_BOARD_FORBIDDEN,
                    "어린이 게시판에는 어린이 회원만 글을 남길 수 있어요.");
        }
    }

    /** 읽을 수 있는가. 어린이 게시판은 아동 본인들과 운영자만. */
    public void assertCanRead(Long userId, Long categoryId) {
        if (!isKidsCategory(categoryId)) return;
        if (isChild(userId)) return;
        if (adminGuard.hasRole(userId, AdminRole.SUPER_ADMIN)
                || adminGuard.hasRole(userId, AdminRole.MODERATOR)) return;
        throw new BusinessException(ErrorCode.KIDS_BOARD_FORBIDDEN);
    }

    /**
     * 전체 피드에서 빼야 할 카테고리 id. 뺄 게 없으면 null.
     *
     * <p>아동이 아니면 어린이 게시판 글은 전체 피드에 섞이지 않는다. <b>운영자도 마찬가지다</b> —
     * 운영자에게 읽기를 연 건 신고 처리를 위해서지 평소 피드에 아이들 글을 흘려보내려는 게 아니다.
     * 필요하면 카테고리를 직접 지정해 들어간다.
     */
    public Long excludedCategoryIdFor(Long userId) {
        if (isChild(userId)) return null;
        return kidsCategoryId();
    }

    /** 이 사용자에게 보여줄 카테고리. 성인에게는 어린이 게시판이 목록에서 아예 빠진다. */
    public List<PostCategoryCd> visibleCategories(Long userId) {
        List<PostCategoryCd> all = categoryRepository.findAllByOrderByDisplayOrderAsc();
        if (isChild(userId)) return all;
        boolean admin = adminGuard.hasRole(userId, AdminRole.SUPER_ADMIN)
                || adminGuard.hasRole(userId, AdminRole.MODERATOR);
        if (admin) return all;
        return all.stream()
                .filter(c -> !KIDS_CATEGORY_CODE.equals(c.getCode()))
                .toList();
    }

    private Long kidsCategoryId() {
        return categoryRepository.findAllByOrderByDisplayOrderAsc().stream()
                .filter(c -> KIDS_CATEGORY_CODE.equals(c.getCode()))
                .map(PostCategoryCd::getId)
                .findFirst()
                .orElse(null);
    }
}
