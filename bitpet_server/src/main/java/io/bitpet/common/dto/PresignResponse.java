package io.bitpet.common.dto;

/**
 * 프로필 이미지 등 단일 파일 업로드용 presigned PUT 응답.
 * 클라이언트는 presignedUrl로 파일을 PUT한 뒤, s3Key를 서버에 저장 요청한다.
 */
public record PresignResponse(String presignedUrl, String s3Key) {}
