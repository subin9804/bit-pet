package io.bitpet.sync.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record SyncPushRequest(
        @NotBlank String clientId,
        @NotEmpty List<PushOperation> operations
) {}
