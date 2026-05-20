package io.bitpet.community.dto;

import jakarta.validation.constraints.NotBlank;

public record CommentCreateRequest(
        Long parentCommentId,
        @NotBlank String content
) {}
