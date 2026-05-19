package io.bitpet.pet.service;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "bitpet.serial-number")
public record SerialNumberProperties(
        String pool,
        int initialLength,
        double expansionThreshold,
        int maxLength
) {}
