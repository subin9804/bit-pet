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
    AUTH_OAUTH_PROVIDER_NOT_SUPPORTED(HttpStatus.BAD_REQUEST, "Unsupported OAuth provider"),
    AUTH_OAUTH_USER_INFO_MISSING(HttpStatus.BAD_REQUEST, "OAuth provider returned insufficient user info"),

    // --- Pet ---
    PET_NOT_FOUND(HttpStatus.NOT_FOUND, "Pet not found"),
    PET_SERIAL_GENERATION_FAILED(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to generate a unique pet serial number"),
    PET_ACCESS_DENIED(HttpStatus.FORBIDDEN, "You do not own this pet"),

    // --- Species ---
    SPECIES_NOT_FOUND(HttpStatus.NOT_FOUND, "Species not found"),

    // --- Pet Relation ---
    PET_RELATION_NOT_FOUND(HttpStatus.NOT_FOUND, "Pet relation not found"),
    PET_RELATION_DUPLICATE(HttpStatus.CONFLICT, "Pet relation already exists"),

    // --- Mating ---
    MATING_NOT_FOUND(HttpStatus.NOT_FOUND, "Mating record not found"),

    // --- Record ---
    WEIGHT_NOT_FOUND(HttpStatus.NOT_FOUND, "Weight record not found"),
    FEEDING_NOT_FOUND(HttpStatus.NOT_FOUND, "Feeding record not found"),
    CLEANING_NOT_FOUND(HttpStatus.NOT_FOUND, "Cleaning record not found"),
    HEALTH_LOG_NOT_FOUND(HttpStatus.NOT_FOUND, "Health log not found"),
    RECORD_ACCESS_DENIED(HttpStatus.FORBIDDEN, "You do not own this record"),
    ;

    private final HttpStatus status;
    private final String defaultMessage;
}
