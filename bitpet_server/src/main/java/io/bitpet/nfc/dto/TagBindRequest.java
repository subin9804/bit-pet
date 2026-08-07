package io.bitpet.nfc.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * 태그 바인딩 요청 (POST /api/v1/nfc/bindings).
 *
 * @param tagCd  태그 코드. 서버가 대문자로 정규화한다
 * @param petId  붙일 개체. 요청자가 <b>소유자(OWNER)</b>여야 한다
 * @param rebind 이미 내 다른 개체에 붙어 있는 태그를 옮길지.
 *               기본 false — 그냥 옮겨 버리면 사용자는 어느 개체의 이름표가 끊겼는지 모른 채
 *               태그를 잃는다. 앱이 "이 태그는 ○○에 연결되어 있어요. 옮길까요?"를 띄우고
 *               사용자가 확인한 뒤에만 true 로 다시 보낸다.
 */
public record TagBindRequest(
        @NotBlank String tagCd,
        @NotNull Long petId,
        boolean rebind
) {}
