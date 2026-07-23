// 08 · 게시글 상세 — 좋아요 / 댓글, 서버 계약 기준 간소화
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/post_models.dart';
import '../data/post_repository.dart';
import '../providers/post_provider.dart';

Color _catBg(String? code) => switch (code?.toUpperCase()) {
      'FREE' => AppColors.commFreeBg,
      'QNA' => AppColors.commQnaBg,
      'INFO' => AppColors.commInfoBg,
      'ADOPTION' => AppColors.commSellBg,
      _ => AppColors.paleBgAlt,
    };

Color _catInk(String? code) => switch (code?.toUpperCase()) {
      'FREE' => AppColors.commFreeInk,
      'QNA' => AppColors.commQnaInk,
      'INFO' => AppColors.commInfoInk,
      'ADOPTION' => AppColors.commSellInk,
      _ => AppColors.paleInk2,
    };

String _relativeTime(DateTime dt) {
  final d = DateTime.now().difference(dt.toLocal());
  if (d.inMinutes < 1) return '방금';
  if (d.inMinutes < 60) return '${d.inMinutes}분 전';
  if (d.inHours < 24) return '${d.inHours}시간 전';
  if (d.inDays == 1) return '어제';
  return '${d.inDays}일 전';
}

class PostDetailScreen extends ConsumerStatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
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
      ref.invalidate(postDetailProvider(widget.postId)); // 댓글 수 갱신
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMenu(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.paleLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: AppColors.primary),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(context);
                context.push('/community/${post.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.commHot),
              title: Text('삭제', style: TextStyle(color: AppColors.commHot)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('게시글 삭제'),
                    content: const Text('정말 삭제하시겠어요?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('삭제')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await ref.read(postRepositoryProvider).deletePost(post.id);
                  ref.invalidate(feedProvider);
                  if (context.mounted) context.pop();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <PostCategory>[];
    final catById = {for (final c in categories) c.id: c};

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: postAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (post) {
          if (post == null) {
            return const Center(child: Text('게시글을 찾을 수 없어요'));
          }
          final cat = catById[post.categoryId];
          final code = cat?.code;
          final label = cat?.nameKo ?? '';

          return Column(
            children: [
              SafeArea(
                bottom: false,
                child: _TopBar(
                  title: '게시글',
                  sub: '$label · 자세히',
                  onBack: () => context.pop(),
                  trailing: GestureDetector(
                    onTap: () => _showMenu(context, post),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.paleLine),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_horiz_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 100),
                  children: [
                    _CategoryPill(code: code, label: label),
                    const SizedBox(height: 10),
                    Text(
                      post.title,
                      style: AppTextStyles.h2
                          .copyWith(letterSpacing: -0.4, height: 1.3),
                    ),
                    const SizedBox(height: 12),

                    // 작성자 행
                    Row(
                      children: [
                        _Avatar(size: 36, imageUrl: post.authorImageUrl),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post.authorName,
                                  style: AppTextStyles.bodyBold
                                      .copyWith(fontSize: 13)),
                              const SizedBox(height: 1),
                              Text(
                                '${_relativeTime(post.createdAt)} · 조회 ${post.viewCount}',
                                style: AppTextStyles.monoXs,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      post.content,
                      style: AppTextStyles.body.copyWith(
                        height: 1.7,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 좋아요
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => ref
                                .read(postDetailProvider(widget.postId)
                                    .notifier)
                                .toggleLike(),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: post.isLiked
                                    ? AppColors.commLikeBg
                                    : AppColors.commLikeBg.withAlpha(100),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    post.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_outline,
                                    size: 16,
                                    color: AppColors.commLikeInk,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '좋아요 ${post.likeCount}',
                                    style: AppTextStyles.bodyBold.copyWith(
                                      fontSize: 13,
                                      color: AppColors.commLikeInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 댓글 헤더
                    RichText(
                      text: TextSpan(
                        text: '댓글 ',
                        style:
                            AppTextStyles.bodyBold.copyWith(fontSize: 14),
                        children: [
                          TextSpan(
                            text: '${post.commentCount}',
                            style: AppTextStyles.bodyBold.copyWith(
                                fontSize: 14, color: AppColors.paleInk2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    commentsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (e, _) => Text(e.toString()),
                      data: (comments) => comments.isEmpty
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('첫 댓글을 남겨보세요',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.paleInk3)),
                              ),
                            )
                          : Column(
                              children: comments
                                  .map((c) => _CommentItem(comment: c))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),

              // 댓글 입력바
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 10, 16,
                    MediaQuery.of(context).viewInsets.bottom +
                        MediaQuery.of(context).padding.bottom +
                        10),
                decoration: const BoxDecoration(
                  color: AppColors.paleBg,
                  border:
                      Border(top: BorderSide(color: AppColors.paleLine)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.primary),
                        decoration: InputDecoration(
                          hintText: '댓글을 남겨보세요…',
                          hintStyle: AppTextStyles.body
                              .copyWith(color: AppColors.paleInk3),
                          isDense: true,
                          enabledBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: AppColors.paleLine),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _isSubmitting ? null : _submitComment,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: _isSubmitting
                            ? const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.paleBg,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check_rounded,
                                color: AppColors.paleBg, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── 공통 위젯들 ─────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  final String? sub;
  final VoidCallback onBack;
  final Widget? trailing;

  const _TopBar({
    required this.title,
    this.sub,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: AppColors.paleBg,
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.paleLine),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: AppColors.primary),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                if (sub != null) Text(sub!, style: AppTextStyles.monoXs),
              ],
            ),
          ),
          if (trailing != null) trailing! else const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String? code;
  final String label;
  const _CategoryPill({required this.code, required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _catBg(code),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          label,
          style: AppTextStyles.monoXs.copyWith(
            color: _catInk(code),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final double size;
  final String? imageUrl;
  const _Avatar({required this.size, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.hardEdge,
      decoration:
          const BoxDecoration(color: AppColors.petSage, shape: BoxShape.circle),
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.pets_rounded,
                  size: size * 0.45, color: AppColors.paleInk2),
            )
          : Icon(Icons.pets_rounded,
              size: size * 0.45, color: AppColors.paleInk2),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final PostComment comment;
  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(size: 32, imageUrl: comment.authorImageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      comment.authorName,
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 12),
                    ),
                    if (comment.isPostAuthor)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.commSellBg,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Text(
                          '작성자',
                          style: AppTextStyles.monoXs.copyWith(
                            fontSize: 9,
                            color: AppColors.commSellInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(
                      _relativeTime(comment.createdAt),
                      style: AppTextStyles.monoXs,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.content,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    height: 1.55,
                    color: AppColors.primary,
                  ),
                ),
                // 대댓글
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...comment.replies.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('↳ ',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.paleInk3)),
                          _Avatar(size: 26, imageUrl: r.authorImageUrl),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(r.authorName,
                                        style: AppTextStyles.bodyBold
                                            .copyWith(fontSize: 12)),
                                    Text(_relativeTime(r.createdAt),
                                        style: AppTextStyles.monoXs),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(r.content,
                                    style: AppTextStyles.body.copyWith(
                                        fontSize: 13,
                                        height: 1.55,
                                        color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
