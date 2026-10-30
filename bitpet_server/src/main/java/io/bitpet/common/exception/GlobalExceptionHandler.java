package io.bitpet.common.exception;

import io.bitpet.common.response.ApiResponse;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.stream.Collectors;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Void>> handleBusiness(BusinessException ex) {
        ErrorCode code = ex.getErrorCode();
        log.warn("BusinessException: code={}, message={}", code, ex.getMessage());
        return ResponseEntity.status(code.getStatus())
                .body(ApiResponse.fail(code, ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(err -> err.getField() + ": " + err.getDefaultMessage())
                .collect(Collectors.joining(", "));
        return ResponseEntity.status(ErrorCode.INVALID_INPUT.getStatus())
                .body(ApiResponse.fail(ErrorCode.INVALID_INPUT, message));
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<Void>> handleConstraintViolation(ConstraintViolationException ex) {
        return ResponseEntity.status(ErrorCode.INVALID_INPUT.getStatus())
                .body(ApiResponse.fail(ErrorCode.INVALID_INPUT, ex.getMessage()));
    }

    @ExceptionHandler({BadCredentialsException.class, AuthenticationException.class})
    public ResponseEntity<ApiResponse<Void>> handleAuthentication(AuthenticationException ex) {
        return ResponseEntity.status(ErrorCode.UNAUTHORIZED.getStatus())
                .body(ApiResponse.fail(ErrorCode.UNAUTHORIZED, ex.getMessage()));
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDenied(AccessDeniedException ex) {
        return ResponseEntity.status(ErrorCode.FORBIDDEN.getStatus())
                .body(ApiResponse.fail(ErrorCode.FORBIDDEN, ex.getMessage()));
    }

    // ⚠️ 없는 정적 파일(/favicon.ico, /robots.txt 등)은 Spring 6.1+ 에서 NoResourceFoundException 으로 온다.
    //    여기서 안 잡으면 아래 Exception 핸들러로 떨어져 500 + 스택트레이스 로그가 남았다.
    @ExceptionHandler({NoHandlerFoundException.class, NoResourceFoundException.class})
    public ResponseEntity<ApiResponse<Void>> handleNoHandler(Exception ex) {
        return ResponseEntity.status(ErrorCode.NOT_FOUND.getStatus())
                .body(ApiResponse.fail(ErrorCode.NOT_FOUND, ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnexpected(Exception ex) {
        log.error("Unhandled exception", ex);
        return ResponseEntity.status(ErrorCode.INTERNAL_ERROR.getStatus())
                .body(ApiResponse.fail(ErrorCode.INTERNAL_ERROR, ErrorCode.INTERNAL_ERROR.getDefaultMessage()));
    }
}
