package io.bitpet.nfc.dto;

import java.time.Instant;
import java.util.List;

/**
 * 미설치자 랜딩 페이지에 보여줄 개체 정보.
 *
 * <p><b>노출 범위</b> — 이름표에 이미 적혀 있을 법한 것 + 주인 닉네임 + 마지막 기록의
 * <b>종류와 시점</b>까지. 기록의 <b>내용</b>(체중 몇 g, 무엇을 급여, 메모 본문)은 담지 않는다.
 * 이 페이지는 로그인도 없이 코드만 알면 열리는 공개 URL 이라, "돌봐지고 있다"는 사실까지만 보인다.
 *
 * <p>생일·입양일·주인 이메일·연락처는 여전히 절대 포함하지 않는다.
 *
 * <p>부모는 {@link TagLandingParent} 참고 — 남의 개체가 섞이는 자리라 노출 범위가 더 좁다.
 */
public record TagLandingPet(
        String name,
        String speciesName,
        List<String> morphNames,
        String genderLabel,      // 수컷 / 암컷 / null(미구분)
        String imageUrl,         // 대표 사진 (없으면 null)
        String ownerName,        // 주인 닉네임. 숨김 설정이면 "비공개", 알 수 없으면 null
        String lastRecordLabel,  // 마지막 기록 종류 (체중/급여/청소/메모) — 없으면 null
        Instant lastRecordAt,    // 마지막 기록 시각 — 없으면 null
        List<TagLandingParent> parents  // 아빠·엄마 (등록된 것만, 없으면 빈 목록)
) {}
