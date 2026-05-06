package io.bitpet.common.exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum ErrorCode {

    // --- Generic ---
    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "Internal server error"),
    INVALID_INPUT(HttpStatus.BAD_REQUEST, "Invalid input"),
    UNAUTHORIZED(HttpStatus.UNAUTHORIZED, "Authentication required"),
    FORBIDDEN(HttpStatus.FORBIDDEN, "Access denied"),
    NOT_FOUND(HttpStatus.NOT_FOUND, "Resource not found"),
    CONFLICT(HttpStatus.CONFLICT, "Resource conflict"),

    // --- Auth ---
    AUTH_INVALID_CREDENTIALS(HttpStatus.UNAUTHORIZED, "Invalid email or password"),
    AUTH_EMAIL_ALREADY_EXISTS(HttpStatus.CONFLICT, "Email already registered"),
    AUTH_INVALID_TOKEN(HttpStatus.UNAUTHORIZED, "Invalid or expired token"),
    AUTH_REFRESH_TOKEN_NOT_FOUND(HttpStatus.UNAUTHORIZED, "Refresh token not found"),
    AUTH_USER_NOT_FOUND(HttpStatus.NOT_FOUND, "User not found"),

    // --- Pet ---
    PET_NOT_FOUND(HttpStatus.NOT_FOUND, "Pet not found"),
    PET_SERIAL_GENERATION_FAILED(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to generate a unique pet serial number"),
    ;

    private final HttpStatus status;
    private final String defaultMessage;
}
