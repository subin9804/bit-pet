package io.bitpet.community.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.community.dto.CommentCreateRequest;
import io.bitpet.community.dto.CommentResponse;
import io.bitpet.community.dto.CommentUpdateRequest;
import io.bitpet.community.dto.LikeToggleResponse;
import io.bitpet.community.dto.PostCreateRequest;
import io.bitpet.community.dto.PostDetailResponse;
import io.bitpet.community.dto.PostPhotoPresignResponse;
import io.bitpet.community.dto.PostPhotoRegisterRequest;
import io.bitpet.community.dto.PostPhotoResponse;
import io.bitpet.community.dto.PostSummaryResponse;
import io.bitpet.community.dto.PostUpdateRequest;
import io.bitpet.community.service.PostService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Post", description = "커뮤니티 게시글 + 댓글 + 좋아요")
@RestController
@RequestMapping("/api/v1/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;

    // -------------------------------------------------------------------------
    // Posts
    // -------------------------------------------------------------------------

    @Operation(summary = "게시글 작성")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<PostDetailResponse> createPost(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody PostCreateRequest request) {
        return ApiResponse.ok(postService.createPost(principal.userId(), request));
    }

    @Operation(summary = "게시글 목록 (카테고리 필터 / 페이지네이션)")
    @GetMapping
    public ApiResponse<Page<PostSummaryResponse>> listPosts(
            @RequestParam(required = false) Long categoryId,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.ok(postService.listPosts(categoryId, pageable));
    }

    @Operation(summary = "내 게시글 목록")
    @GetMapping("/mine")
    public ApiResponse<Page<PostSummaryResponse>> listMyPosts(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ApiResponse.ok(postService.listMyPosts(principal.userId(), pageable));
    }

    @Operation(summary = "게시글 상세 조회 (조회수 +1)")
    @GetMapping("/{postId}")
    public ApiResponse<PostDetailResponse> getPost(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long postId) {
        return ApiResponse.ok(postService.getPost(principal.userId(), postId));
    }

    @Operation(summary = "게시글 수정")
    @PatchMapping("/{postId}")
    public ApiResponse<PostDetailResponse> updatePost(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long postId,
            @Valid @RequestBody PostUpdateRequest request) {
        return ApiResponse.ok(postService.updatePost(principal.userId(), postId, request));
    }

    @Operation(summary = "게시글 삭제 (Soft Delete)")
    @DeleteMapping("/{postId}")
    public ApiResponse<Void> deletePost(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long postId) {
        postService.deletePost(principal.userId(), postId);
        return ApiResponse.ok();
    }

    // -------------------------------------------------------------------------
    // Post Photos
    // -------------------------------------------------------------------------

    @Operation(summary = "게시글 이미지 presigned PUT URL 발급")
    @PostMapping("/{postId}/photos/presign")
    public ApiResponse<PostPhotoPresignResponse> presignPhoto(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long postId,
            @RequestParam String filename) {
        return ApiResponse.ok(postService.generatePhotoPresignedUrl(principal.userId(), postId, filename));
    }

    @Operation(summary = "게시글 이미지 등록 (S3 업로드 완료 후)")
    @PostMapping("/{postId}/photos")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<PostPhotoResponse> registerPhoto(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long postId,
            @Valid @RequestBody PostPhotoRegisterRequest request) {
        return ApiResponse.ok(postService.registerPhoto(principal.userId(), postId, request));
    }

    @Operation(summary = "게시글 이미지 삭제")
    @DeleteMapping("/{postId}/photos/{photoId}")
    public ApiResponse<Void> deletePhoto(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long postId,
            @PathVariable Long photoId) {
        postService.deletePhoto(principal.userId(), postId, photoId);
        return ApiResponse.ok();
    }

    // -------------------------------------------------------------------------
    // Comments
    // -------------------------------------------------------------------------

    @Operation(summary = "댓글 목록 조회 (트리 구조)")
    @GetMapping("/{postId}/comments")
    public ApiResponse<List<CommentResponse>> listComments(@PathVariable Long postId) {
        return ApiResponse.ok(postService.listComments(postId));
    }

    @Operation(summary = "댓글 작성 (parentCommentId 있으면 대댓글)")
    @PostMapping("/{postId}/comments")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<CommentResponse> createComment(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long postId,
            @Valid @RequestBody CommentCreateRequest request) {
        return ApiResponse.ok(postService.createComment(principal.userId(), postId, request));
    }

    @Operation(summary = "댓글 수정")
    @PatchMapping("/{postId}/comments/{commentId}")
    public ApiResponse<CommentResponse> updateComment(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long postId,
            @PathVariable Long commentId,
            @Valid @RequestBody CommentUpdateRequest request) {
        return ApiResponse.ok(postService.updateComment(principal.userId(), postId, commentId, request));
    }

    @Operation(summary = "댓글 삭제 (Soft Delete)")
    @DeleteMapping("/{postId}/comments/{commentId}")
    public ApiResponse<Void> deleteComment(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long postId,
            @PathVariable Long commentId) {
        postService.deleteComment(principal.userId(), postId, commentId);
        return ApiResponse.ok();
    }

    // -------------------------------------------------------------------------
    // Like
    // -------------------------------------------------------------------------

    @Operation(summary = "좋아요 토글 (좋아요 ↔ 취소)")
    @PostMapping("/{postId}/like")
    public ApiResponse<LikeToggleResponse> toggleLike(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long postId) {
        return ApiResponse.ok(postService.toggleLike(principal.userId(), postId));
    }
}
