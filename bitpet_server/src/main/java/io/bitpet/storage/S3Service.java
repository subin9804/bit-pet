package io.bitpet.storage;

import io.bitpet.common.config.S3Properties;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.time.Duration;

@Service
@RequiredArgsConstructor
public class S3Service {

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;
    private final S3Properties s3Properties;

    public PresignedPutObjectRequest presignPut(String s3Key, String contentType) {
        PutObjectRequest putRequest = PutObjectRequest.builder()
                .bucket(s3Properties.bucket())
                .key(s3Key)
                .contentType(contentType)
                .build();

        return s3Presigner.presignPutObject(PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(s3Properties.presignTtlMinutes()))
                .putObjectRequest(putRequest)
                .build());
    }

    public PresignedGetObjectRequest presignGet(String s3Key) {
        GetObjectRequest getRequest = GetObjectRequest.builder()
                .bucket(s3Properties.bucket())
                .key(s3Key)
                .build();

        return s3Presigner.presignGetObject(GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(s3Properties.presignTtlMinutes()))
                .getObjectRequest(getRequest)
                .build());
    }

    public void deleteObject(String s3Key) {
        s3Client.deleteObject(DeleteObjectRequest.builder()
                .bucket(s3Properties.bucket())
                .key(s3Key)
                .build());
    }

    /**
     * 저장된 이미지 참조값을 표시용 URL로 해석한다.
     * - null/빈값 → null
     * - http(s)로 시작(OAuth 외부 프로필 등) → 그대로 사용
     * - 그 외(우리 S3 key) → presigned GET URL 발급
     */
    public String resolveUrl(String stored) {
        if (stored == null || stored.isBlank()) return null;
        if (stored.startsWith("http://") || stored.startsWith("https://")) return stored;
        return presignGet(stored).url().toString();
    }
}
