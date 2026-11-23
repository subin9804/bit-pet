package io.bitpet.community.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.community.dto.MyCommentResponse;
import io.bitpet.community.dto.PostSummaryResponse;
import io.bitpet.community.service.PostService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 프로필 화면의 '작성한 글·댓글' (2026-11-23). 커뮤니티 작성자 닉네임을 눌러 들어온다.
 * 프로필 본체(닉네임·공개 개체)는 {@code pet.controller.UserProfileController} 에 있다.
 */
@Tag(name = "User Activity", description = "다른 사용자의 커뮤니티 활동")
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserActivityController {

    private final PostService postService;

    @Operation(summary = "사용자가 쓴 게시글 목록 (보는 사람 기준 차단·어린이 게시판 규칙 적용)")
    @GetMapping("/{userId}/posts")
    public ApiResponse<Page<PostSummaryResponse>> listPosts(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long userId,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.ok(postService.listUserPosts(principal.userId(), userId, pageable));
    }

    @Operation(summary = "사용자가 쓴 댓글 목록 (보는 사람이 열 수 있는 글에 달린 것만)")
    @GetMapping("/{userId}/comments")
    public ApiResponse<Page<MyCommentResponse>> listComments(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long userId,
            @PageableDefault(size = 20) Pageable pageable) {
        return ApiResponse.ok(postService.listUserComments(principal.userId(), userId, pageable));
    }
}
