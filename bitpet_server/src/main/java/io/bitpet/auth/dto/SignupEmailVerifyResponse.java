package io.bitpet.auth.dto;

/** 가입 요청의 {@code emailVerificationToken} 으로 그대로 보낸다 */
public record SignupEmailVerifyResponse(String verificationToken) {}
