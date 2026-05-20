package io.bitpet.community.controller;

import io.bitpet.common.response.ApiResponse;
import io.bitpet.community.dto.PostCategoryResponse;
import io.bitpet.community.service.PostService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "PostCategory", description = "게시판 카테고리 조회")
@RestController
@RequestMapping("/api/v1/post-categories")
@RequiredArgsConstructor
public class PostCategoryController {

    private final PostService postService;

    @Operation(summary = "카테고리 목록 조회")
    @GetMapping
    public ApiResponse<List<PostCategoryResponse>> list() {
        return ApiResponse.ok(postService.listCategories());
    }
}
