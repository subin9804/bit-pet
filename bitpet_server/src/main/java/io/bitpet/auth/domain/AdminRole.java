package io.bitpet.auth.domain;

/**
 * 운영자 권한 등급 (admin_role_rls.role).
 *
 * <p>개체 권한({@link io.bitpet.pet.domain.PetKeeperRole} OWNER/KEEPER)과는 <b>완전히 다른 축</b>이다.
 * 개체 권한은 "이 개체에 대해 뭘 할 수 있나"이고, 이쪽은 "서비스 전체에 대해 뭘 할 수 있나"다.
 * 한 사람이 SUPER_ADMIN 이면서 어떤 개체의 KEEPER 일 수 있고, 둘은 서로를 대신하지 못한다.
 *
 * <p>등급을 늘리려면 (1) 여기에 상수를 추가하고 (2) 마이그레이션으로
 * {@code ck_admin_role_rls_role} CHECK 제약을 넓히면 된다. 제약을 <b>넓히는</b> 방향이라
 * 무중단 배포 중에도 안전하다 — 구버전 앱은 새 등급을 모를 뿐, 터지지 않는다.
 * 반대로 등급을 <b>없애는</b> 건 제약을 좁히는 것이라 반드시 두 번에 나눠야 한다.
 */
public enum AdminRole {
    /** 최상위 운영자 — 공지 작성, 권한 부여, 되돌릴 수 없는 조치 */
    SUPER_ADMIN,
    /** 중간 운영자 — 신고 처리·게시글 숨김 등 회수 가능한 조치 */
    MODERATOR
}
