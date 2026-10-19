// 08 · 게시글 상세 — 좋아요 / 댓글, 서버 계약 기준 간소화
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/toast_message.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/post_models.dart';
import '../data/models/report_models.dart';
import '../data/post_repository.dart';
import '../providers/post_provider.dart';
import 'post_photo_carousel.dart';
import 'report_actions.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_network_image.dart';

Color _catBg(String? code) => switch (code?.toUpperCase()) {
  'FREE' => AppColors.commFreeBg,
  'QNA' => AppColors.commQnaBg,
  'INFO' => AppColors.commInfoBg,
  'ADOPTION' => AppColors.commSellBg,
  _ => AppColors.bgAlt,
};

Color _catInk(String? code) => switch (code?.toUpperCase()) {
  'FREE' => AppColors.commFreeInk,
  'QNA' => AppColors.commQnaInk,
  'INFO' => AppColors.commInfoInk,
  'ADOPTION' => AppColors.commSellInk,
  _ => AppColors.ink2,
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
    } catch (e) {
      // 조용히 삼키면 어린이 게시판 제한(CHILD_BOARD_ONLY)에 걸렸을 때
      // 버튼만 되살아나고 아무 일도 안 일어난 것처럼 보인다.
      if (mounted) {
        showToast(
          context,
          serverMessageOf(e) ?? '댓글을 남기지 못했어요.',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 게시글 메뉴. 내 글이면 수정/삭제, 남의 글이면 신고/차단 — **섞이면 안 된다**.
  /// (예전엔 소유자 판정 없이 수정/삭제를 보여줬다. 서버가 403 을 주긴 했지만
  ///  남의 글에 삭제 버튼이 보이는 것 자체가 사고다.)
  void _showMenu(BuildContext context, Post post) {
    final myId = ref.read(authStateProvider).valueOrNull?.id;
    final isMine = myId != null && myId == post.userId;

    showBitpetSheet(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: isMine
            ? _ownerTiles(context, post)
            : reportBlockTiles(
                context: context,
                ref: ref,
                targetType: ReportTargetType.post,
                targetId: post.id,
                authorUserId: post.userId,
                authorName: post.authorName,
                onDone: () {
                  // 차단·신고 후에는 이 글이 더는 보이면 안 된다 → 목록으로 되돌린다
                  ref.invalidate(feedProvider);
                  if (mounted) context.pop();
                },
              ),
      ),
      title: isMine ? '내 게시글' : '게시글',
    );
  }

  List<Widget> _ownerTiles(BuildContext context, Post post) => [
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.edit_outlined, color: AppColors.ink),
      title: const Text('수정'),
      onTap: () {
        Navigator.pop(context);
        context.push('/community/${post.id}/edit');
      },
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.delete_outline, color: AppColors.commHot),
      title: Text('삭제', style: TextStyle(color: AppColors.commHot)),
      onTap: () async {
        Navigator.pop(context);
        final ok = await ConfirmModal.show(
          context,
          title: '게시글 삭제',
          message: '정말 삭제하시겠어요? 되돌릴 수 없어요.',
          confirmLabel: '삭제',
          isDangerous: true,
        );
        if (ok && context.mounted) {
          await ref.read(postRepositoryProvider).deletePost(post.id);
          ref.invalidate(feedProvider);
          if (context.mounted) context.pop();
        }
      },
    ),
  ];

  /// 댓글 메뉴. 내 댓글은 아직 앱에서 수정/삭제를 지원하지 않으므로
  /// 남의 댓글일 때만 시트를 연다 (내 댓글은 아예 아이콘을 숨긴다).
  void _showCommentMenu(BuildContext context, PostComment comment) {
    showBitpetSheet(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: reportBlockTiles(
          context: context,
          ref: ref,
          targetType: ReportTargetType.comment,
          targetId: comment.id,
          authorUserId: comment.userId,
          authorName: comment.authorName,
          onDone: () {
            ref.invalidate(commentsProvider(widget.postId));
            ref.invalidate(feedProvider);
          },
        ),
      ),
      title: '댓글',
    );
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <PostCategory>[];
    final catById = {for (final c in categories) c.id: c};

    final loadedPost = postAsync.valueOrNull;
    final headerLabel = loadedPost == null
        ? null
        : catById[loadedPost.categoryId]?.nameKo;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      // 손으로 그린 상단바(흰 띠 + 테두리 원형 뒤로가기 + 가운데 제목 2줄 '게시글 / 자유 · 자세히')였다.
      // 흰 띠가 연회색 본문 위에 따로 떠서 한 화면이 두 장으로 보였다 — 다른 하위 화면처럼 AppBar.
      // 게시판 이름은 제목에 바로 올린다('자세히'는 읽을 정보가 없는 말이다).
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(
          headerLabel == null || headerLabel.isEmpty ? '게시글' : headerLabel,
        ),
        titleSpacing: 0,
        actions: [
          if (loadedPost != null)
            IconButton(
              tooltip: '더보기',
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMenu(context, loadedPost),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: postAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        // 예외 문자열을 그대로 띄웠다 — 사용자는 읽을 수 없고 할 수 있는 것도 없다.
        error: (e, _) => EmptyState(
          message: '불러오지 못했어요',
          subMessage: '연결을 확인하고 다시 시도해주세요.',
          icon: Icons.cloud_off,
          tone: EmptyTone.neutral,
          actionLabel: '다시 시도',
          onAction: () => ref.invalidate(postDetailProvider(widget.postId)),
        ),
        data: (post) {
          if (post == null) {
            return const EmptyState(
              message: '게시글을 찾을 수 없어요',
              subMessage: '삭제되었거나 볼 수 없는 글이에요.',
              icon: Icons.article_outlined,
              tone: EmptyTone.neutral,
            );
          }
          final cat = catById[post.categoryId];
          final code = cat?.code;
          final label = cat?.nameKo ?? '';
          // 아동은 일반 게시판을 읽기만 한다 (서버 CHILD_BOARD_ONLY).
          // 입력바·좋아요를 열어두고 누른 뒤에 거절하면 쓴 댓글을 버리게 된다.
          final isChild =
              ref.watch(authStateProvider).valueOrNull?.isChild ?? false;
          final readOnly = isChild && code != kKidsCategoryCode;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    100,
                  ),
                  children: [
                    _SectionCard(
                      children: [
                        _CategoryPill(code: code, label: label),
                        const SizedBox(height: 8),
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
                            _Avatar(size: 36, imageUrl: post.authorImageUrl),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.authorName,
                                    style: AppTextStyles.bodyBold.copyWith(
                                      fontSize: 13,
                                    ),
                                  ),
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
                            color: post.isBlinded
                                ? AppColors.ink3
                                : AppColors.ink,
                            fontStyle: post.isBlinded
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 첨부 사진 — 세로로 쌓지 않고 한 칸짜리 캐러셀로 넘겨 본다.
                        // (탭하면 전체화면, 개체 갤러리 뷰어와 같은 조작)
                        if (post.photos.isNotEmpty)
                          PostPhotoCarousel(post.photoUrls),

                        // 좋아요 — 가려진 글에는 달지 않는다. 읽기 전용(아동·일반 게시판)도 숨긴다
                        if (!post.isBlinded && !readOnly)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => ref
                                      .read(
                                        postDetailProvider(
                                          widget.postId,
                                        ).notifier,
                                      )
                                      .toggleLike(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: post.isLiked
                                          ? AppColors.commLikeBg
                                          : AppColors.commLikeBg.withAlpha(100),
                                      borderRadius: AppRadius.brMd,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AppIcon(
                                          post.isLiked
                                              ? AppIcons.like
                                              : AppIcons.likeLine,
                                          size: 16,
                                          color: AppColors.commLikeInk,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '좋아요 ${post.likeCount}',
                                          style: AppTextStyles.bodyBold
                                              .copyWith(
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
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      children: [
                        // 댓글 헤더
                        RichText(
                          text: TextSpan(
                            text: '댓글 ',
                            style: AppTextStyles.bodyBold.copyWith(
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: '${post.commentCount}',
                                style: AppTextStyles.bodyBold.copyWith(
                                  fontSize: 14,
                                  color: AppColors.ink2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        commentsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                '댓글을 불러오지 못했어요',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.ink3,
                                ),
                              ),
                            ),
                          ),
                          data: (comments) => comments.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Center(
                                    child: Text(
                                      readOnly ? '아직 댓글이 없어요' : '첫 댓글을 남겨보세요',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.ink3,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: comments
                                      .map(
                                        (c) => _CommentItem(
                                          comment: c,
                                          myUserId: ref
                                              .watch(authStateProvider)
                                              .valueOrNull
                                              ?.id,
                                          onMenu: (target) =>
                                              _showCommentMenu(context, target),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 읽기 전용이면 입력바 대신 안내 한 줄
              if (readOnly)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    border: Border(top: BorderSide(color: AppColors.line)),
                  ),
                  child: Text(
                    '어린이 회원은 어린이 게시판에서만 글·댓글을 남길 수 있어요',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink3,
                    ),
                  ),
                )
              else
                // 댓글 입력바
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(context).viewInsets.bottom +
                        MediaQuery.of(context).padding.bottom +
                        8,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    border: Border(top: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: '댓글을 남겨보세요…',
                            hintStyle: AppTextStyles.body.copyWith(
                              color: AppColors.ink3,
                            ),
                            isDense: true,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.line),
                            ),
                            // 포커스 밑줄이 먹색이었다 — 앱 입력칸은 포커스를 브랜드색으로 보인다.
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.brandAction,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 보내기 — 검정 원(먹색 `primary`)이었다. 눌리는 주 행동은 브랜드색이다.
                      GestureDetector(
                        onTap: _isSubmitting ? null : _submitComment,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.brandAction,
                            shape: BoxShape.circle,
                          ),
                          child: _isSubmitting
                              ? const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.bg,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: AppColors.bg,
                                  size: 20,
                                ),
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

class _CategoryPill extends StatelessWidget {
  final String? code;
  final String label;
  const _CategoryPill({required this.code, required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _catBg(code),
          borderRadius: AppRadius.brPill,
        ),
        child: Text(
          label,
          style: AppTextStyles.monoXs.copyWith(
            color: _catInk(code),
            fontWeight: FontWeight.w700,
            fontSize: 12,
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
      decoration: const BoxDecoration(
        color: AppColors.bgAlt,
        shape: BoxShape.circle,
      ),
      child: imageUrl != null
          ? AppNetworkImage(
              imageUrl,
              fit: BoxFit.cover,
              memWidth: (size * 3).round(),
              placeholder: Icon(
                Icons.person,
                size: size * 0.62,
                color: AppColors.ink3,
              ),
            )
          : Icon(Icons.person, size: size * 0.62, color: AppColors.ink3),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final PostComment comment;
  final int? myUserId;
  final void Function(PostComment target) onMenu;

  const _CommentItem({
    required this.comment,
    required this.myUserId,
    required this.onMenu,
  });

  /// 내 댓글에는 신고·차단이 의미가 없으므로 메뉴 자체를 숨긴다.
  /// 이미 가려진 댓글도 마찬가지 — 더 신고할 것이 없다.
  bool _canReport(PostComment c) =>
      !c.isBlinded && (myUserId == null || myUserId != c.userId);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(size: 32, imageUrl: comment.authorImageUrl),
          const SizedBox(width: 8),
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
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.commSellBg,
                          borderRadius: AppRadius.brPill,
                        ),
                        child: Text(
                          '작성자',
                          style: AppTextStyles.monoXs.copyWith(
                            fontSize: 12,
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
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    height: 1.55,
                    color: comment.isBlinded ? AppColors.ink3 : AppColors.ink,
                    fontStyle: comment.isBlinded
                        ? FontStyle.italic
                        : FontStyle.normal,
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
                          Text(
                            '↳ ',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.ink3,
                            ),
                          ),
                          _Avatar(size: 26, imageUrl: r.authorImageUrl),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(
                                      r.authorName,
                                      style: AppTextStyles.bodyBold.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _relativeTime(r.createdAt),
                                      style: AppTextStyles.monoXs,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  r.content,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 13,
                                    height: 1.55,
                                    color: r.isBlinded
                                        ? AppColors.ink3
                                        : AppColors.ink,
                                    fontStyle: r.isBlinded
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_canReport(r)) _MenuDot(onTap: () => onMenu(r)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_canReport(comment)) _MenuDot(onTap: () => onMenu(comment)),
        ],
      ),
    );
  }
}

/// 댓글 오른쪽의 작은 ⋯ — 신고·차단 진입점.
/// 눌러야 알 수 있게 크게 두면 "신고하세요"처럼 보여서, 존재만 알 정도로 흐리게 둔다.
class _MenuDot extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuDot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Icon(Icons.more_horiz_rounded, size: 16, color: AppColors.ink3),
      ),
    );
  }
}

/// 본문 / 댓글을 각각 흰 카드 한 장에 얹는다. 캔버스에 글자만 흘려 두면 화면 전체가
/// 회색 한 면이라 어디까지가 글이고 어디부터 댓글인지 경계가 없었다(2026-10-19).
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: AppDecor.cardRaised,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}
