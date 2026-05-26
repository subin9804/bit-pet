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

    // --- Morph ---
    MORPH_NOT_FOUND(HttpStatus.NOT_FOUND, "Morph not found"),
    MORPH_SPECIES_MISMATCH(HttpStatus.BAD_REQUEST, "Morph does not belong to the given species"),

    // --- Pet Relation ---
    PET_RELATION_NOT_FOUND(HttpStatus.NOT_FOUND, "Pet relation not found"),
    PET_RELATION_DUPLICATE(HttpStatus.CONFLICT, "Pet relation already exists"),

    // --- Mating ---
    MATING_NOT_FOUND(HttpStatus.NOT_FOUND, "Mating record not found"),
    MATING_OWNER_REQUIRED(HttpStatus.BAD_REQUEST, "At least one pet must be owned by you"),
    MATING_PET_NOT_FEMALE(HttpStatus.BAD_REQUEST, "petIdFemale must be a female pet"),
    MATING_PET_NOT_MALE(HttpStatus.BAD_REQUEST, "petIdMale must be a male pet"),

    // --- Laying ---
    LAYING_NOT_FOUND(HttpStatus.NOT_FOUND, "Laying record not found"),
    LAYING_PET_NOT_FEMALE(HttpStatus.BAD_REQUEST, "Laying pet must be female"),
    LAYING_FERTILE_EXCEEDS_TOTAL(HttpStatus.BAD_REQUEST, "Fertile egg count exceeds total egg count"),
    LAYING_MATING_MISMATCH(HttpStatus.BAD_REQUEST, "Mating female pet does not match laying pet"),
    HATCH_NOT_FOUND(HttpStatus.NOT_FOUND, "Hatch record not found"),
    HATCH_INVALID_STATUS_TRANSITION(HttpStatus.BAD_REQUEST, "Invalid hatch status transition"),

    // --- Memo ---
    MEMO_NOT_FOUND(HttpStatus.NOT_FOUND, "Memo not found"),
    MEMO_VET_EXT_REQUIRED(HttpStatus.BAD_REQUEST, "VET tag memo requires vetExt fields"),
    MEMO_TAG_INVALID(HttpStatus.BAD_REQUEST, "Invalid tag code"),

    // --- Calendar ---
    CALENDAR_MONTH_INVALID(HttpStatus.BAD_REQUEST, "yearMonth format must be YYYY-MM"),

    // --- Record ---
    WEIGHT_NOT_FOUND(HttpStatus.NOT_FOUND, "Weight record not found"),
    FEEDING_NOT_FOUND(HttpStatus.NOT_FOUND, "Feeding record not found"),
    CLEANING_NOT_FOUND(HttpStatus.NOT_FOUND, "Cleaning record not found"),
    HEALTH_LOG_NOT_FOUND(HttpStatus.NOT_FOUND, "Health log not found"),
    RECORD_ACCESS_DENIED(HttpStatus.FORBIDDEN, "You do not own this record"),

    // --- Routine ---
    ROUTINE_NOT_FOUND(HttpStatus.NOT_FOUND, "Routine not found"),
    ROUTINE_ACCESS_DENIED(HttpStatus.FORBIDDEN, "You do not own this routine"),
    ROUTINE_NO_PETS(HttpStatus.BAD_REQUEST, "No pets subscribed to this routine"),
    ROUTINE_LOG_NOT_FOUND(HttpStatus.NOT_FOUND, "Routine log not found"),

    // --- Notification ---
    NOTIFICATION_NOT_FOUND(HttpStatus.NOT_FOUND, "Notification not found"),

    // --- Photo ---
    PHOTO_NOT_FOUND(HttpStatus.NOT_FOUND, "Photo not found"),
    PHOTO_ENTITY_TYPE_INVALID(HttpStatus.BAD_REQUEST, "Invalid entityType"),

    // --- Community ---
    POST_NOT_FOUND(HttpStatus.NOT_FOUND, "Post not found"),
    POST_ACCESS_DENIED(HttpStatus.FORBIDDEN, "You do not own this post"),
    COMMENT_NOT_FOUND(HttpStatus.NOT_FOUND, "Comment not found"),
    COMMENT_ACCESS_DENIED(HttpStatus.FORBIDDEN, "You do not own this comment"),
    POST_PHOTO_LIMIT_EXCEEDED(HttpStatus.BAD_REQUEST, "Post can have at most 5 photos"),
    CATEGORY_NOT_FOUND(HttpStatus.NOT_FOUND, "Category not found"),
    ;

    private final HttpStatus status;
    private final String defaultMessage;
}
