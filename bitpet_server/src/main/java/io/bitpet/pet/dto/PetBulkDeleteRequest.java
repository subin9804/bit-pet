package io.bitpet.pet.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * 개체 일괄 삭제 요청.
 *
 * <p>중복 id는 서버에서 제거하므로 클라이언트가 걸러낼 필요 없다.
 * 상한(200)은 한 트랜잭션에서 처리할 수 있는 현실적인 크기를 잡은 것 —
 * 목록 화면에서 전체 선택해도 이 범위를 넘기 어렵다.
 */
public record PetBulkDeleteRequest(
        @NotEmpty(message = "삭제할 개체를 선택하세요")
        @Size(max = 200, message = "한 번에 최대 200마리까지 삭제할 수 있습니다")
        List<Long> petIds
) {}
