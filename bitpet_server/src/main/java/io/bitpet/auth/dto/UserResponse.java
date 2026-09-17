package io.bitpet.auth.dto;

import io.bitpet.auth.domain.AdminRole;
import io.bitpet.auth.domain.UserMst;

import java.time.Instant;
import java.util.List;

public record UserResponse(
        Long id,
        String email,
        String nickname,
        String userType,
        String profileImageUrl,
        /**
         * 프로필 색 팔레트 키 (sage/peach/sky/lilac/butter/coral).
         * 사진이 없으면 아바타 배경색, 있으면 테두리 색으로 쓰인다.
         */
        String profileColor,
        /** 가계도에 닉네임을 노출할지 (마이페이지 설정 토글) */
        boolean showNicknameInPedigree,
        /**
         * 운영자 등급 목록. 일반 사용자는 빈 배열이다.
         *
         * <p>앱이 <b>화면(공지 작성 버튼 등)을 켤지 정하는 데만</b> 쓴다. 실제 차단은 서버가
         * 매 요청마다 DB로 다시 판정한다 — 이 값은 응답에 담겨 나간 뒤 사용자가 고칠 수 있고,
         * 권한을 회수해도 앱이 다시 /me 를 부를 때까지 옛 값을 들고 있기 때문이다.
         */
        List<String> adminRoles,
        /**
         * 지금 만 14세 미만인가 (V12). 저장값이 아니라 조회 시점에 생년월일로 계산한다 —
         * 생일이 지나면 그날부터 일반 회원과 같아져야 하는데, 저장해두면 그 전환이 일어나지 않는다.
         *
         * <p>앱은 이 값으로 '자녀 계정' 메뉴를 감추고 어린이 게시판 안내를 띄운다.
         * 실제 차단은 서버가 매 요청 판정한다 ({@code KidsBoardPolicy}).
         */
        boolean isChild,
        Instant createdAt
) {
    public static UserResponse from(UserMst user) {
        return from(user, user.getProfileImageUrl());
    }

    /** profileImageUrl을 표시용으로 해석한 값(presigned GET 등)을 주입해 생성 */
    public static UserResponse from(UserMst user, String resolvedImageUrl) {
        return from(user, resolvedImageUrl, List.of());
    }

    public static UserResponse from(UserMst user, String resolvedImageUrl, List<AdminRole> roles) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getUserType().name(),
                resolvedImageUrl,
                user.getProfileColor(),
                user.isShowNicknameInPedigree(),
                roles.stream().map(Enum::name).toList(),
                user.isChild(),
                user.getCreatedAt()
        );
    }
}
