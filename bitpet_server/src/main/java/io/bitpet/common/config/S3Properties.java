package io.bitpet.common.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("bitpet.s3")
public record S3Properties(
        String endpoint,
        String region,
        String bucket,
        String accessKey,
        String secretKey,
        int presignTtlMinutes,
        boolean pathStyleAccess
) {}
