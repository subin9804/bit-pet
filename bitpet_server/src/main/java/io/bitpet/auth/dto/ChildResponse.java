package io.bitpet.auth.dto;

import io.bitpet.auth.domain.UserMst;

import java.time.Instant;
import java.time.LocalDate;

/**
 * 보호자가 보는 자녀 계정 (V12).
 *
 * <p>⛔ 비밀번호·토큰은 물론이고 <b>자녀의 게시글 내용도 여기 담지 않는다.</b> 보호자의 감독은
 * '자녀 활동 보기'라는 별도 경로로 하고, 이 응답은 "어떤 계정이 내 자녀로 달려 있는가"까지다.
 */
public record ChildResponse(
        Long id,
        String email,
        String nickname,
        String profileImageUrl,
        String profileColor,
        LocalDate birthDate,
        /**
         * 지금도 만 14세 미만인가. 저장된 값이 아니라 <b>조회 시점에 계산</b>한다 —
         * 자녀가 만 14세가 되면 그날부터 일반 회원과 같아지고, 보호자 화면은 그걸 알려야 한다.
         */
        boolean isChild,
        Instant createdAt
) {
    public static ChildResponse from(UserMst child) {
        return new ChildResponse(
                child.getId(),
                child.getEmail(),
                child.getName(),
                child.getProfileImageUrl(),
                child.getProfileColor(),
                child.getBirthDate(),
                child.isChild(),
                child.getCreatedAt()
        );
    }
}
