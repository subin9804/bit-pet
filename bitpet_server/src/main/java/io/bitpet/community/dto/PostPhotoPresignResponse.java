package io.bitpet.community.dto;

import java.time.Instant;

public record PostPhotoPresignResponse(String uploadUrl, String s3Key, Instant expiration) {}
