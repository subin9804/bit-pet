package io.bitpet.group.dto;

public record InviteCodeResponse(
        String code,
        int expiresInSeconds
) {}
