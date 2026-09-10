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
                user.isShowNicknameInPedigree(),
                roles.stream().map(Enum::name).toList(),
                user.getCreatedAt()
        );
    }
}
