package io.bitpet.notification.dto;

import io.bitpet.notification.domain.DevicePlatform;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record DeviceTokenRegisterRequest(
        @NotBlank @Size(max = 255) String deviceToken,
        @NotNull DevicePlatform platform,
        @Size(max = 255) String deviceInfo
) {}
