import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../../community/data/models/post_models.dart';
import '../../community/providers/post_provider.dart';
import '../../../core/widgets/app_network_image.dart';

/// 마이페이지 > 내 게시글 — 내가 쓴 글과 댓글을 탭으로 나눠 보여준다.
///
/// 두 탭 모두 무한 스크롤. 커뮤니티 피드와 같은 페이지네이션 방식이다.
class MyActivityScreen extends ConsumerStatefulWidget {
  const MyActivityScreen({super.key});

  @override
  ConsumerState<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends ConsumerState<MyActivityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        titleSpacing: 0,
        title: const Text('내 게시글'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.brandAction,
          unselectedLabelColor: AppColors.ink3,
          indicatorColor: AppColors.brandAction,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: AppTextStyles.bodyBold,
          unselectedLabelStyle: AppTextStyles.body,
          tabs: const [
            Tab(text: '작성한 글'),
            Tab(text: '작성한 댓글'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_MyPostsTab(), _MyCommentsTab()],
      ),
    );
  }
}

/// 스크롤이 바닥 근처에 닿으면 다음 페이지를 부른다.
bool _nearBottom(ScrollNotification n) =>
    n.metrics.pixels >= n.metrics.maxScrollExtent - 300;

// ── 작성한 글 ────────────────────────────────────────────────────────────────

class _MyPostsTab extends ConsumerWidget {
  const _MyPostsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myPostsProvider);
    final notifier = ref.read(myPostsProvider.notifier);

    if (state.loading) {
      return const SkeletonCardList();
    }
    if (state.error != null) {
      return _ErrorRetry(onRetry: notifier.refresh);
    }
    if (state.posts.isEmpty) {
      return const EmptyState(
        icon: Icons.article_outlined,
        message: '작성한 글이 없어요',
        subMessage: '커뮤니티에 첫 글을 남겨 보세요.',
      );
    }

    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (_nearBottom(n)) notifier.loadMore();
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: state.posts.length + (state.hasMore ? 1 : 0),
          itemBuilder: (_, i) {
            if (i >= state.posts.length) return const _LoadingRow();
            final post = state.posts[i];
            final cat = _findCategory(categories, post.categoryId);
            return _MyPostRow(
              post: post,
              categoryLabel: cat?.nameKo,
              onTap: () => context.push('/community/${post.id}'),
            );
          },
        ),
      ),
    );
  }
}

PostCategory? _findCategory(List<PostCategory> all, int id) {
  for (final c in all) {
    if (c.id == id) return c;
  }
  return null;
}

class _MyPostRow extends StatelessWidget {
  final Post post;
  final String? categoryLabel;
  final VoidCallback onTap;

  const _MyPostRow({
    required this.post,
    required this.categoryLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _RowCard(
      onTap: onTap,
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (categoryLabel != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.brandTint,
                            borderRadius: AppRadius.brPill,
                          ),
                          child: Text(
                            categoryLabel!,
                            style: AppTextStyles.monoXs.copyWith(
                              color: AppColors.brandTintInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        relativeTime(post.createdAt),
                        style: AppTextStyles.monoXs
                            .copyWith(color: AppColors.ink3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.title,
                    style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 14,
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Meta(icon: AppIcons.likeLine, value: post.likeCount),
                      const SizedBox(width: 12),
                      _Meta(
                          icon: AppIcons.comment,
                          value: post.commentCount),
                      const SizedBox(width: 12),
                      Text('조회 ${post.viewCount}',
                          style: AppTextStyles.monoXs
                              .copyWith(color: AppColors.ink3)),
                    ],
                  ),
                ],
              ),
            ),
            if (post.thumbnailUrl != null) ...[
              const SizedBox(width: 12),
              // ⚠️ clipBehavior 는 decoration 이 있어야 한다 — color: 만 주면
              // assert 로 터져서 '작성한 글' 탭 전체가 안 그려졌다(2026-10-19).
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.bgAlt,
                  borderRadius: AppRadius.brMd,
                ),
                clipBehavior: Clip.antiAlias,
                child: AppNetworkImage(
                  post.thumbnailUrl,
                  fit: BoxFit.cover,
                  memWidth: 240,
                  placeholder: const Center(
                    child: Icon(Icons.image_outlined,
                        size: 24, color: AppColors.ink3),
                  ),
                ),
              ),
            ],
          ],
        ),
    );
  }
}

// ── 작성한 댓글 ──────────────────────────────────────────────────────────────

class _MyCommentsTab extends ConsumerWidget {
  const _MyCommentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myCommentsProvider);
    final notifier = ref.read(myCommentsProvider.notifier);

    if (state.loading) {
      return const SkeletonCardList();
    }
    if (state.error != null) {
      return _ErrorRetry(onRetry: notifier.refresh);
    }
    if (state.comments.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        message: '작성한 댓글이 없어요',
        subMessage: '다른 사육자의 글에 댓글을 남겨 보세요.',
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (_nearBottom(n)) notifier.loadMore();
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: state.comments.length + (state.hasMore ? 1 : 0),
          itemBuilder: (_, i) {
            if (i >= state.comments.length) return const _LoadingRow();
            final c = state.comments[i];
            return _MyCommentRow(
              comment: c,
              onTap: () {
                // 원글이 지워졌으면 이동할 곳이 없다. 탭을 무시하는 대신
                // 왜 안 열리는지 알려준다.
                if (c.postDeleted) {
                  showToast(context, '원글이 삭제되어 열 수 없어요.');
                  return;
                }
                context.push('/community/${c.postId}');
              },
            );
          },
        ),
      ),
    );
  }
}

class _MyCommentRow extends StatelessWidget {
  final MyComment comment;
  final VoidCallback onTap;

  const _MyCommentRow({required this.comment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dimmed = comment.postDeleted;

    return _RowCard(
      onTap: onTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 내가 쓴 댓글 본문이 주인공이라 위에 둔다.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (comment.isReply) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.subdirectory_arrow_right,
                        size: 16, color: AppColors.ink3),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    comment.content,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      height: 1.45,
                      color: dimmed ? AppColors.ink3 : AppColors.ink,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 어느 글에 단 댓글인지
            Row(
              children: [
                Icon(
                  dimmed ? Icons.block : Icons.article_outlined,
                  size: 16,
                  color: AppColors.ink3,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    comment.postTitle,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      fontStyle: dimmed ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  relativeTime(comment.createdAt),
                  style:
                      AppTextStyles.monoXs.copyWith(color: AppColors.ink3),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

// ── 공용 조각 ────────────────────────────────────────────────────────────────

class _Meta extends StatelessWidget {
  /// [AppIcons] 의 SVG 경로. 하트와 말풍선이 한 줄에 붙는 자리라 한쪽만 Material 로
  /// 두면 그 칩만 선 굵기가 달라 보인다.
  final String icon;
  final int value;
  const _Meta({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 16, color: AppColors.ink3),
        const SizedBox(width: 4),
        Text('$value',
            style: AppTextStyles.monoXs.copyWith(color: AppColors.ink2)),
      ],
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}

class _ErrorRetry extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      tone: EmptyTone.neutral,
      message: '목록을 불러오지 못했어요',
      subMessage: '잠시 후 다시 시도해 주세요.',
      actionLabel: '다시 시도',
      onAction: onRetry,
    );
  }
}

/// 글·댓글 한 건 = 흰 카드 한 장. 캔버스 위에 선만 그어 두면 행 경계가 흐려서
/// 마이 메뉴 카드와 같은 [AppDecor.cardRaised] 를 쓴다.
class _RowCard extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _RowCard({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: AppDecor.cardRaised,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 커뮤니티 피드와 같은 규칙의 상대 시간 표기.
String relativeTime(DateTime dt) {
  final d = DateTime.now().difference(dt.toLocal());
  if (d.inMinutes < 1) return '방금';
  if (d.inMinutes < 60) return '${d.inMinutes}분 전';
  if (d.inHours < 24) return '${d.inHours}시간 전';
  if (d.inDays == 1) return '어제';
  return '${d.inDays}일 전';
}
