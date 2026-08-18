package io.bitpet.community.service;

import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.repository.AdminRoleRlsRepository;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.community.domain.PostCommentDtl;
import io.bitpet.community.domain.PostLikeRls;
import io.bitpet.community.domain.PostMst;
import io.bitpet.community.domain.PostPhotoDtl;
import io.bitpet.community.dto.CommentCreateRequest;
import io.bitpet.community.dto.CommentResponse;
import io.bitpet.community.dto.CommentUpdateRequest;
import io.bitpet.community.dto.LikeToggleResponse;
import io.bitpet.community.dto.MyCommentResponse;
import io.bitpet.community.dto.PostCategoryResponse;
import io.bitpet.community.dto.PostCreateRequest;
import io.bitpet.community.dto.PostDetailResponse;
import io.bitpet.community.dto.PostPhotoPresignResponse;
import io.bitpet.community.dto.PostPhotoRegisterRequest;
import io.bitpet.community.dto.PostPhotoResponse;
import io.bitpet.community.dto.PostSummaryResponse;
import io.bitpet.community.dto.PostUpdateRequest;
import io.bitpet.community.repository.PostCategoryCdRepository;
import io.bitpet.community.repository.PostCommentDtlRepository;
import io.bitpet.community.repository.PostLikeRlsRepository;
import io.bitpet.community.repository.PostMstRepository;
import io.bitpet.community.repository.PostPhotoDtlRepository;
import io.bitpet.storage.S3Service;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PostService {

    private static final int MAX_PHOTOS_PER_POST = 5;

    private final PostMstRepository postRepository;
    private final PostCategoryCdRepository categoryRepository;
    private final PostPhotoDtlRepository photoRepository;
    private final PostCommentDtlRepository commentRepository;
    private final PostLikeRlsRepository likeRepository;
    private final UserMstRepository userRepository;
    private final AdminRoleRlsRepository adminRepository;
    private final S3Service s3Service;

    // -------------------------------------------------------------------------
    // Category
    // -------------------------------------------------------------------------

    public List<PostCategoryResponse> listCategories() {
        return categoryRepository.findAllByOrderByDisplayOrderAsc()
                .stream().map(PostCategoryResponse::from).toList();
    }

    // -------------------------------------------------------------------------
    // Post CRUD
    // -------------------------------------------------------------------------

    @Transactional
    public PostDetailResponse createPost(Long userId, PostCreateRequest req) {
        verifyCategory(req.categoryId());
        PostMst post = postRepository.save(PostMst.builder()
                .userId(userId)
                .categoryId(req.categoryId())
                .title(req.title())
                .content(req.content())
                .build());
        UserMst author = userRepository.findById(userId).orElse(null);
        return PostDetailResponse.of(post, false, List.of(),
                nameOf(author), imageOf(author));
    }

    public Page<PostSummaryResponse> listPosts(Long userId, Long categoryId, Pageable pageable) {
        // 공지 우선 정렬은 @Query 에서 처리 → sort 제거하고 page/size 만 전달
        Pageable pageOnly = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize());
        Page<PostMst> page = categoryId != null
                ? postRepository.findByCategoryOrdered(categoryId, pageOnly)
                : postRepository.findAllOrdered(pageOnly);
        return toSummaryPage(userId, page);
    }

    public Page<PostSummaryResponse> listMyPosts(Long userId, Pageable pageable) {
        return toSummaryPage(userId, postRepository.findByUserId(userId, pageable));
    }

    /**
     * 내가 쓴 댓글 목록.
     *
     * <p>원글 제목을 붙이려고 게시글을 조회하는데, 댓글마다 한 번씩 부르면 N+1 이 된다.
     * postId 를 모아 한 번에 읽고 맵으로 붙인다. 원글이 소프트 삭제됐으면 맵에 없으므로
     * {@code postTitle = null} 로 흘러가 '삭제된 게시글' 로 표시된다.
     */
    public Page<MyCommentResponse> listMyComments(Long userId, Pageable pageable) {
        Page<PostCommentDtl> page =
                commentRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
        List<PostCommentDtl> comments = page.getContent();

        Set<Long> postIds = comments.stream()
                .map(PostCommentDtl::getPostId).collect(Collectors.toSet());
        Map<Long, PostMst> posts = postIds.isEmpty()
                ? Map.of()
                : postRepository.findAllById(postIds).stream()
                        .collect(Collectors.toMap(PostMst::getId, p -> p));

        List<MyCommentResponse> content = comments.stream().map(c -> {
            PostMst post = posts.get(c.getPostId());
            return MyCommentResponse.of(c,
                    post == null ? null : post.getTitle(),
                    post == null ? null : post.getCategoryId());
        }).toList();

        return new PageImpl<>(content, page.getPageable(), page.getTotalElements());
    }

    private Page<PostSummaryResponse> toSummaryPage(Long userId, Page<PostMst> page) {
        List<PostMst> posts = page.getContent();
        Map<Long, UserMst> authors = loadAuthors(
                posts.stream().map(PostMst::getUserId).collect(Collectors.toSet()));
        Set<Long> liked = likedPostIds(userId,
                posts.stream().map(PostMst::getId).collect(Collectors.toSet()));

        List<PostSummaryResponse> content = posts.stream().map(p -> {
            List<PostPhotoDtl> photos = photoRepository.findAllByPostIdOrderByDisplayOrderAsc(p.getId());
            String thumbnail = photos.isEmpty() ? null
                    : s3Service.presignGet(photos.get(0).getS3Key()).url().toString();
            UserMst author = authors.get(p.getUserId());
            return PostSummaryResponse.of(p, thumbnail,
                    nameOf(author), imageOf(author), liked.contains(p.getId()));
        }).toList();

        return new PageImpl<>(content, page.getPageable(), page.getTotalElements());
    }

    @Transactional
    public PostDetailResponse getPost(Long userId, Long postId) {
        PostMst post = findPost(postId);
        post.incrementViewCount();

        boolean likedByMe = likeRepository.existsByPostIdAndUserId(postId, userId);
        List<PostPhotoResponse> photos = buildPhotoResponses(postId);
        UserMst author = userRepository.findById(post.getUserId()).orElse(null);
        return PostDetailResponse.of(post, likedByMe, photos, nameOf(author), imageOf(author));
    }

    @Transactional
    public PostDetailResponse updatePost(Long userId, Long postId, PostUpdateRequest req) {
        PostMst post = findPost(postId);
        verifyPostOwner(post, userId);
        verifyCategory(req.categoryId());
        post.update(req.categoryId(), req.title(), req.content());

        boolean likedByMe = likeRepository.existsByPostIdAndUserId(postId, userId);
        List<PostPhotoResponse> photos = buildPhotoResponses(postId);
        UserMst author = userRepository.findById(post.getUserId()).orElse(null);
        return PostDetailResponse.of(post, likedByMe, photos, nameOf(author), imageOf(author));
    }

    @Transactional
    public void deletePost(Long userId, Long postId) {
        PostMst post = findPost(postId);
        verifyPostOwner(post, userId);

        // S3 이미지 삭제 후 soft delete
        photoRepository.findAllByPostIdOrderByDisplayOrderAsc(postId)
                .forEach(p -> s3Service.deleteObject(p.getS3Key()));
        post.softDelete();
    }

    /** 공지 상단 고정/해제 — 관리자(admin_role_rls)만 가능 */
    @Transactional
    public void setPinned(Long userId, Long postId, boolean pinned) {
        if (!adminRepository.existsByUserId(userId)) {
            throw new BusinessException(ErrorCode.POST_ACCESS_DENIED);
        }
        PostMst post = findPost(postId);
        post.setPinned(pinned);
    }

    // -------------------------------------------------------------------------
    // Post Photos
    // -------------------------------------------------------------------------

    public PostPhotoPresignResponse generatePhotoPresignedUrl(Long userId, Long postId, String filename) {
        PostMst post = findPost(postId);
        verifyPostOwner(post, userId);

        if (photoRepository.countByPostId(postId) >= MAX_PHOTOS_PER_POST) {
            throw new BusinessException(ErrorCode.POST_PHOTO_LIMIT_EXCEEDED);
        }

        String ext = extractExtension(filename);
        String s3Key = "posts/" + postId + "/" + UUID.randomUUID() + (ext.isEmpty() ? "" : "." + ext);
        PresignedPutObjectRequest presigned = s3Service.presignPut(s3Key, resolveContentType(ext));
        return new PostPhotoPresignResponse(presigned.url().toString(), s3Key, presigned.expiration());
    }

    @Transactional
    public PostPhotoResponse registerPhoto(Long userId, Long postId, PostPhotoRegisterRequest req) {
        PostMst post = findPost(postId);
        verifyPostOwner(post, userId);

        if (photoRepository.countByPostId(postId) >= MAX_PHOTOS_PER_POST) {
            throw new BusinessException(ErrorCode.POST_PHOTO_LIMIT_EXCEEDED);
        }

        PostPhotoDtl saved = photoRepository.save(PostPhotoDtl.builder()
                .postId(postId)
                .s3Key(req.s3Key())
                .displayOrder(req.displayOrder())
                .width(req.width())
                .height(req.height())
                .build());

        return PostPhotoResponse.of(saved, s3Service.presignGet(saved.getS3Key()).url().toString());
    }

    @Transactional
    public void deletePhoto(Long userId, Long postId, Long photoId) {
        PostMst post = findPost(postId);
        verifyPostOwner(post, userId);

        PostPhotoDtl photo = photoRepository.findById(photoId)
                .filter(p -> p.getPostId().equals(postId))
                .orElseThrow(() -> new BusinessException(ErrorCode.PHOTO_NOT_FOUND));

        photoRepository.delete(photo);
        s3Service.deleteObject(photo.getS3Key());
    }

    // -------------------------------------------------------------------------
    // Comments
    // -------------------------------------------------------------------------

    public List<CommentResponse> listComments(Long postId) {
        PostMst post = findPost(postId);
        List<PostCommentDtl> all = commentRepository.findAllByPostIdOrderByCreatedAtAsc(postId);
        Map<Long, UserMst> authors = loadAuthors(
                all.stream().map(PostCommentDtl::getUserId).collect(Collectors.toSet()));
        Long postAuthorId = post.getUserId();

        Map<Long, List<CommentResponse>> repliesByParent = all.stream()
                .filter(c -> c.getParentCommentId() != null)
                .collect(Collectors.groupingBy(
                        PostCommentDtl::getParentCommentId,
                        Collectors.mapping(c -> toCommentResponse(c, List.of(), authors, postAuthorId),
                                Collectors.toList())
                ));

        return all.stream()
                .filter(c -> c.getParentCommentId() == null)
                .map(c -> toCommentResponse(c,
                        repliesByParent.getOrDefault(c.getId(), List.of()), authors, postAuthorId))
                .toList();
    }

    @Transactional
    public CommentResponse createComment(Long userId, Long postId, CommentCreateRequest req) {
        PostMst post = findPost(postId);

        if (req.parentCommentId() != null) {
            commentRepository.findById(req.parentCommentId())
                    .filter(c -> c.getPostId().equals(postId))
                    .orElseThrow(() -> new BusinessException(ErrorCode.COMMENT_NOT_FOUND));
        }

        PostCommentDtl saved = commentRepository.save(PostCommentDtl.builder()
                .postId(postId)
                .userId(userId)
                .parentCommentId(req.parentCommentId())
                .content(req.content())
                .build());

        post.incrementCommentCount();
        UserMst author = userRepository.findById(userId).orElse(null);
        return CommentResponse.of(saved, List.of(), nameOf(author), imageOf(author),
                userId.equals(post.getUserId()));
    }

    @Transactional
    public CommentResponse updateComment(Long userId, Long postId, Long commentId, CommentUpdateRequest req) {
        PostMst post = findPost(postId);
        PostCommentDtl comment = findComment(commentId, postId);
        verifyCommentOwner(comment, userId);
        comment.update(req.content());
        UserMst author = userRepository.findById(userId).orElse(null);
        return CommentResponse.of(comment, List.of(), nameOf(author), imageOf(author),
                userId.equals(post.getUserId()));
    }

    @Transactional
    public void deleteComment(Long userId, Long postId, Long commentId) {
        PostMst post = findPost(postId);
        PostCommentDtl comment = findComment(commentId, postId);
        verifyCommentOwner(comment, userId);
        comment.softDelete();
        post.decrementCommentCount();
    }

    // -------------------------------------------------------------------------
    // Like toggle
    // -------------------------------------------------------------------------

    @Transactional
    public LikeToggleResponse toggleLike(Long userId, Long postId) {
        PostMst post = findPost(postId);
        Optional<PostLikeRls> existing = likeRepository.findByPostIdAndUserId(postId, userId);

        boolean liked;
        if (existing.isPresent()) {
            likeRepository.delete(existing.get());
            post.decrementLikeCount();
            liked = false;
        } else {
            likeRepository.save(PostLikeRls.builder().postId(postId).userId(userId).build());
            post.incrementLikeCount();
            liked = true;
        }
        return new LikeToggleResponse(liked, post.getLikeCount());
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private Map<Long, UserMst> loadAuthors(Collection<Long> userIds) {
        if (userIds.isEmpty()) return Map.of();
        return userRepository.findAllById(userIds).stream()
                .collect(Collectors.toMap(UserMst::getId, u -> u));
    }

    private Set<Long> likedPostIds(Long userId, Collection<Long> postIds) {
        if (postIds.isEmpty()) return Set.of();
        return likeRepository.findByUserIdAndPostIdIn(userId, postIds).stream()
                .map(PostLikeRls::getPostId).collect(Collectors.toSet());
    }

    private CommentResponse toCommentResponse(PostCommentDtl c, List<CommentResponse> replies,
                                              Map<Long, UserMst> authors, Long postAuthorId) {
        UserMst author = authors.get(c.getUserId());
        return CommentResponse.of(c, replies, nameOf(author), imageOf(author),
                c.getUserId().equals(postAuthorId));
    }

    private static String nameOf(UserMst u) { return u != null ? u.getName() : "알 수 없음"; }

    private static String imageOf(UserMst u) { return u != null ? u.getProfileImageUrl() : null; }

    private PostMst findPost(Long postId) {
        return postRepository.findById(postId)
                .orElseThrow(() -> new BusinessException(ErrorCode.POST_NOT_FOUND));
    }

    private PostCommentDtl findComment(Long commentId, Long postId) {
        PostCommentDtl comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new BusinessException(ErrorCode.COMMENT_NOT_FOUND));
        if (!comment.getPostId().equals(postId)) {
            throw new BusinessException(ErrorCode.COMMENT_NOT_FOUND);
        }
        return comment;
    }

    private void verifyPostOwner(PostMst post, Long userId) {
        if (!post.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.POST_ACCESS_DENIED);
        }
    }

    private void verifyCommentOwner(PostCommentDtl comment, Long userId) {
        if (!comment.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.COMMENT_ACCESS_DENIED);
        }
    }

    private void verifyCategory(Long categoryId) {
        if (!categoryRepository.existsById(categoryId)) {
            throw new BusinessException(ErrorCode.CATEGORY_NOT_FOUND);
        }
    }

    private List<PostPhotoResponse> buildPhotoResponses(Long postId) {
        return photoRepository.findAllByPostIdOrderByDisplayOrderAsc(postId)
                .stream()
                .map(p -> PostPhotoResponse.of(p, s3Service.presignGet(p.getS3Key()).url().toString()))
                .toList();
    }

    private static String extractExtension(String filename) {
        if (filename == null || !filename.contains(".")) return "";
        return filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
    }

    private static String resolveContentType(String ext) {
        return switch (ext) {
            case "jpg", "jpeg" -> "image/jpeg";
            case "png"         -> "image/png";
            case "webp"        -> "image/webp";
            case "heic"        -> "image/heic";
            default            -> "application/octet-stream";
        };
    }
}
