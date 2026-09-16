package io.bitpet.nfc.dto;

import java.util.List;

/**
 * 랜딩 페이지에 보여줄 부모 개체 한 마리.
 *
 * <p><b>부모는 남의 개체일 수 있다.</b> 가계도 부모 등록은 상대 승인 없이 되므로
 * (CLAUDE.md "가계도 부모 등록"), 이름표를 산 사람이 자기 개체에 남의 개체를 부모로 걸어두면
 * 그 남의 개체 정보가 아무나 여는 공개 URL 에 실려 나가게 된다. 그래서 여기 담기는 건
 * <b>이름</b>과, 조건을 만족할 때의 <b>모프</b>뿐이다. 사진·성별·주인·일련번호는 담지 않는다.
 *
 * @param roleLabel  "아빠" / "엄마"
 * @param name       개체 이름. 주인이 탈퇴한 익명화 개체도 이름은 남는다(V54)
 * @param morphNames 모프. 공개 조건을 만족하지 못하면 <b>빈 목록</b>
 */
public record TagLandingParent(
        String roleLabel,
        String name,
        List<String> morphNames
) {}
