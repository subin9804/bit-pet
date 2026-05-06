package io.bitpet.common.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

@ConfigurationProperties(prefix = "bitpet.security")
public record SecurityProperties(
        Cors cors,
        List<String> publicPaths
) {
    public record Cors(
            List<String> allowedOrigins,
            List<String> allowedMethods,
            List<String> allowedHeaders,
            boolean allowCredentials
    ) {}
}
