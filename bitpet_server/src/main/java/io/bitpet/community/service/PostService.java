package io.bitpet.community.service;

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
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Optional;
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
        return PostDetailResponse.of(post, false, List.of());
    }

    public Page<PostSummaryResponse> listPosts(Long categoryId, Pageable pageable) {
        Page<PostMst> page = categoryId != null
                ? postRepository.findByCategoryId(categoryId, pageable)
                : postRepository.findAllBy(pageable);

        return page.map(p -> {
            List<PostPhotoDtl> photos = photoRepository.findAllByPostIdOrderByDisplayOrderAsc(p.getId());
            String thumbnail = photos.isEmpty() ? null
                    : s3Service.presignGet(photos.get(0).getS3Key()).url().toString();
            return PostSummaryResponse.of(p, thumbnail);
        });
    }

    public Page<PostSummaryResponse> listMyPosts(Long userId, Pageable pageable) {
        return postRepository.findByUserId(userId, pageable).map(p -> {
            List<PostPhotoDtl> photos = photoRepository.findAllByPostIdOrderByDisplayOrderAsc(p.getId());
            String thumbnail = photos.isEmpty() ? null
                    : s3Service.presignGet(photos.get(0).getS3Key()).url().toString();
            return PostSummaryResponse.of(p, thumbnail);
        });
    }

    @Transactional
    public PostDetailResponse getPost(Long userId, Long postId) {
        PostMst post = findPost(postId);
        post.incrementViewCount();

        boolean likedByMe = likeRepository.existsByPostIdAndUserId(postId, userId);
        List<PostPhotoResponse> photos = buildPhotoResponses(postId);
        return PostDetailResponse.of(post, likedByMe, photos);
    }

    @Transactional
    public PostDetailResponse updatePost(Long userId, Long postId, PostUpdateRequest req) {
        PostMst post = findPost(postId);
        verifyPostOwner(post, userId);
        verifyCategory(req.categoryId());
        post.update(req.categoryId(), req.title(), req.content());

        boolean likedByMe = likeRepository.existsByPostIdAndUserId(postId, userId);
        List<PostPhotoResponse> photos = buildPhotoResponses(postId);
        return PostDetailResponse.of(post, likedByMe, photos);
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
        findPost(postId);
        List<PostCommentDtl> all = commentRepository.findAllByPostIdOrderByCreatedAtAsc(postId);

        Map<Long, List<CommentResponse>> repliesByParent = all.stream()
                .filter(c -> c.getParentCommentId() != null)
                .collect(Collectors.groupingBy(
                        PostCommentDtl::getParentCommentId,
                        Collectors.mapping(c -> CommentResponse.of(c, List.of()), Collectors.toList())
                ));

        return all.stream()
                .filter(c -> c.getParentCommentId() == null)
                .map(c -> CommentResponse.of(c, repliesByParent.getOrDefault(c.getId(), List.of())))
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
        return CommentResponse.of(saved, List.of());
    }

    @Transactional
    public CommentResponse updateComment(Long userId, Long postId, Long commentId, CommentUpdateRequest req) {
        findPost(postId);
        PostCommentDtl comment = findComment(commentId, postId);
        verifyCommentOwner(comment, userId);
        comment.update(req.content());
        return CommentResponse.of(comment, List.of());
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
