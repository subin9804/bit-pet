// 08 · 게시글 상세 — PALE 디자인 핸드오프 반영
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/post_models.dart';
import '../data/post_repository.dart';
import '../providers/post_provider.dart';

Color _catBg(String? cat) => switch (cat?.toLowerCase()) {
      'free' => AppColors.commFreeBg,
      'qna'  => AppColors.commQnaBg,
      'info' => AppColors.commInfoBg,
      'sell' => AppColors.commSellBg,
      _      => AppColors.paleBgAlt,
    };

Color _catInk(String? cat) => switch (cat?.toLowerCase()) {
      'free' => AppColors.commFreeInk,
      'qna'  => AppColors.commQnaInk,
      'info' => AppColors.commInfoInk,
      'sell' => AppColors.commSellInk,
      _      => AppColors.paleInk2,
    };

String _catLabel(String? cat) => switch (cat?.toLowerCase()) {
      'free' => '자유',
      'qna'  => 'QnA',
      'info' => '정보',
      'sell' => '분양',
      _      => cat ?? '',
    };

String _relativeTime(DateTime dt) {
  final d = DateTime.now().difference(dt);
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
              title: Text('삭제',
                  style:
                      TextStyle(color: AppColors.commHot)),
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
                  await ref
                      .read(postRepositoryProvider)
                      .deletePost(post.id);
                  if (context.mounted) context.pop();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined,
                  color: AppColors.paleInk2),
              title: const Text('신고'),
              onTap: () => Navigator.pop(context),
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

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: postAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (post) {
          if (post == null) {
            return const Center(child: Text('게시글을 찾을 수 없어요'));
          }
          final cat = post.categoryCode.toLowerCase();

          return Column(
            children: [
              // ── TopBar ──────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: _TopBar(
                  title: '게시글',
                  sub: '${_catLabel(cat)} · 자세히',
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

              // ── 본문 스크롤 ──────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.fromLTRB(22, 4, 22, 100),
                  children: [
                    // 카테고리 pill + HOT
                    Row(
                      children: [
                        _CategoryPill(cat: cat),
                        if (post.isHot) ...[
                          const SizedBox(width: 6),
                          Text(
                            'HOT',
                            style: AppTextStyles.monoXs.copyWith(
                              color: AppColors.commHot,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 제목
                    Text(
                      post.title,
                      style: AppTextStyles.h2.copyWith(
                        letterSpacing: -0.4,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 작성자 행
                    Row(
                      children: [
                        _AvatarCircle(size: 36, color: AppColors.petSage),
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
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.paleLine),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '+ 팔로우',
                            style: AppTextStyles.caption
                                .copyWith(fontSize: 11, color: AppColors.paleInk2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 본문 텍스트
                    Text(
                      post.content,
                      style: AppTextStyles.body.copyWith(
                        height: 1.7,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 첨부 이미지 placeholder
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.petSage,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            size: 48, color: AppColors.paleInk3),
                      ),
                    ),

                    // 해시태그
                    if (post.tags.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: post.tags
                            .map((tg) => _TagChip(label: tg))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 반응 바
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => ref
                                .read(postDetailProvider(widget.postId)
                                    .notifier)
                                .toggleLike(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
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
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => ref
                              .read(postDetailProvider(widget.postId)
                                  .notifier)
                              .toggleBookmark(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border:
                                  Border.all(color: AppColors.paleLine),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Icon(
                              post.isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_outline,
                              size: 18,
                              color: post.isBookmarked
                                  ? AppColors.primary
                                  : AppColors.paleInk2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            border: Border.all(color: AppColors.paleLine),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: const Center(
                            child: Text('↗',
                                style: TextStyle(
                                    fontSize: 16, color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 댓글 헤더
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: '댓글 ',
                            style: AppTextStyles.bodyBold
                                .copyWith(fontSize: 14),
                            children: [
                              TextSpan(
                                text: '${post.commentCount}',
                                style: AppTextStyles.bodyBold.copyWith(
                                    fontSize: 14,
                                    color: AppColors.paleInk2),
                              ),
                            ],
                          ),
                        ),
                        Text('최신순 ↓',
                            style: AppTextStyles.caption
                                .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 댓글 목록
                    commentsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child:
                            Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (e, _) => Text(e.toString()),
                      data: (comments) => Column(
                        children: comments
                            .map((c) => _CommentItem(comment: c))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 댓글 입력바 ─────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 10, 16,
                    MediaQuery.of(context).viewInsets.bottom +
                        MediaQuery.of(context).padding.bottom +
                        10),
                decoration: const BoxDecoration(
                  color: AppColors.paleBg,
                  border: Border(
                      top: BorderSide(color: AppColors.paleLine)),
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
                            borderSide: BorderSide(color: AppColors.paleLine),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
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
                if (sub != null)
                  Text(
                    sub!,
                    style: AppTextStyles.monoXs,
                  ),
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
  final String cat;
  const _CategoryPill({required this.cat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _catBg(cat),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        _catLabel(cat),
        style: AppTextStyles.monoXs.copyWith(
          color: _catInk(cat),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.paleBgAlt,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label.startsWith('#') ? label : '#$label',
        style: AppTextStyles.caption
            .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _AvatarCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Icon(Icons.pets_rounded,
            size: size * 0.45, color: AppColors.paleInk2),
      ),
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
          _AvatarCircle(
            size: 32,
            color: comment.isAuthor ? AppColors.petLilac : AppColors.petSky,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자 행
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      comment.authorName,
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 12),
                    ),
                    if (comment.isAuthor)
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
                // 본문
                Text(
                  comment.content,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    height: 1.55,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                // 액션
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_outline,
                              size: 13, color: AppColors.paleInk2),
                          const SizedBox(width: 3),
                          Text(
                            '${comment.likeCount}',
                            style: AppTextStyles.monoXs.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.paleInk2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        '답글',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.paleInk2,
                        ),
                      ),
                    ),
                  ],
                ),
                // 대댓글 보기
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.paleBgAlt,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      '↳ 답글 ${comment.replies.length}개 보기',
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
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
