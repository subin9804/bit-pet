package io.bitpet.photo.dto;

import java.time.Instant;

/**
 * presign 응답 — 원본과 썸네일 두 벌을 <b>한 번에</b> 내린다.
 *
 * <p>썸네일 presign 을 따로 부르게 두지 않는 이유는 두 가지다. 왕복이 한 번 더 늘고,
 * 무엇보다 <b>키 규칙을 서버가 쥐고 있어야</b> 한다 — 앱이 키를 만들어 올리면 사진마다
 * 다른 규칙이 섞이고 삭제·정리 경로가 그 키를 찾지 못한다.
 *
 * <p>썸네일 업로드는 <b>선택</b>이다. 앱이 축소에 실패하면 {@code thumbPresignedUrl} 을
 * 쓰지 않고 register 에서 {@code thumbS3Key} 를 비워 보내면 된다 (원본만 남는다).
 */
public record PresignedUploadResponse(
        String presignedUrl,
        String s3Key,
        String thumbPresignedUrl,
        String thumbS3Key,
        Instant expiresAt
) {}
