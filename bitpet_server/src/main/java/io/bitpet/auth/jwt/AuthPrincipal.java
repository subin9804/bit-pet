package io.bitpet.auth.jwt;

import java.io.Serializable;

public record AuthPrincipal(
        Long userId,
        String email,
        String role
) implements Serializable {}
