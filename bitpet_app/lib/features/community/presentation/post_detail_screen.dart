import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/post_repository.dart';
import '../providers/post_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(postRepositoryProvider)
          .addComment(widget.postId, _commentCtrl.text.trim());
      _commentCtrl.clear();
      ref.invalidate(commentsProvider(widget.postId));
    } catch (e) {
      if (mounted) {
        ToastMessage.show(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(commentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (post) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 게시글 헤더
                  Row(
                    children: [
                      _CategoryBadge(code: post.categoryCode),
                      const Spacer(),
                      Text(
                          '${post.createdAt.year}.${post.createdAt.month}.${post.createdAt.day}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(post.title, style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  Text(post.authorName,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary)),
                  const Divider(height: 24),
                  Text(post.content, style: AppTextStyles.body),
                  const SizedBox(height: 16),
                  // 좋아요·조회수
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          try {
                            await ref
                                .read(postRepositoryProvider)
                                .toggleLike(post.id, post.isLiked);
                            ref.invalidate(postDetailProvider(post.id));
                          } catch (e) {
                            if (context.mounted) {
                              ToastMessage.show(context, e.toString(),
                                  type: ToastType.error);
                            }
                          }
                        },
                        child: Row(
                          children: [
                            Icon(
                              post.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: post.isLiked
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text('${post.likeCount}',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.remove_red_eye_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${post.viewCount}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                  const Divider(height: 32),
                  // 댓글
                  Text('댓글 ${post.commentCount}',
                      style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  commentsAsync.when(
                    loading: () =>
                        const CircularProgressIndicator(),
                    error: (e, _) => Text(e.toString()),
                    data: (comments) => Column(
                      children: comments
                          .map((c) => Padding(
                                padding: EdgeInsets.only(
                                  left:
                                      c.parentCommentId != null ? 24 : 0,
                                  bottom: 12,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (c.parentCommentId != null)
                                      const Icon(Icons.subdirectory_arrow_right,
                                          size: 16,
                                          color: AppColors.textDisabled),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(c.authorName,
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                      color: AppColors
                                                          .primary)),
                                          Text(c.content,
                                              style: AppTextStyles.body),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            // 댓글 입력
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(
                        hintText: '댓글을 입력하세요',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _isSubmitting ? null : _submitComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String code;
  const _CategoryBadge({required this.code});

  String get label => switch (code) {
        'FREE' => '자유',
        'QNA' => 'Q&A',
        'INFO' => '정보',
        'ADOPTION' => '분양',
        _ => code,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.label.copyWith(color: AppColors.primary)),
    );
  }
}
