package io.bitpet.auth.oauth;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "bitpet.oauth2")
public record OAuth2Properties(
        String successRedirectUri,
        String failureRedirectUri
) {}
