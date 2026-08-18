import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/toast_message.dart';
import '../../community/data/models/post_models.dart';
import '../../community/providers/post_provider.dart';

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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('내 게시글'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.paleInk3,
          indicatorColor: AppColors.primary,
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
      return const Center(child: CircularProgressIndicator());
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.paleLineSoft)),
        ),
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
                              horizontal: 7, vertical: 2),
                          color: AppColors.bg2,
                          child: Text(
                            categoryLabel!,
                            style: AppTextStyles.monoXs.copyWith(
                              color: AppColors.paleInk2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        relativeTime(post.createdAt),
                        style: AppTextStyles.monoXs
                            .copyWith(color: AppColors.paleInk3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.title,
                    style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 14,
                      color: AppColors.primary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Meta(icon: Icons.favorite_outline, value: post.likeCount),
                      const SizedBox(width: 12),
                      _Meta(
                          icon: Icons.chat_bubble_outline,
                          value: post.commentCount),
                      const SizedBox(width: 12),
                      Text('조회 ${post.viewCount}',
                          style: AppTextStyles.monoXs
                              .copyWith(color: AppColors.paleInk3)),
                    ],
                  ),
                ],
              ),
            ),
            if (post.thumbnailUrl != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 60,
                color: AppColors.bg2,
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  post.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.image_outlined,
                        size: 24, color: AppColors.paleInk3),
                  ),
                ),
              ),
            ],
          ],
        ),
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
      return const Center(child: CircularProgressIndicator());
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

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.paleLineSoft)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 내가 쓴 댓글 본문이 주인공이라 위에 둔다.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (comment.isReply) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.subdirectory_arrow_right,
                        size: 14, color: AppColors.paleInk3),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    comment.content,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      height: 1.45,
                      color: dimmed ? AppColors.paleInk3 : AppColors.primary,
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
                  size: 13,
                  color: AppColors.paleInk3,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    comment.postTitle,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
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
                      AppTextStyles.monoXs.copyWith(color: AppColors.paleInk3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 공용 조각 ────────────────────────────────────────────────────────────────

class _Meta extends StatelessWidget {
  final IconData icon;
  final int value;
  const _Meta({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.paleInk3),
        const SizedBox(width: 3),
        Text('$value',
            style: AppTextStyles.monoXs.copyWith(color: AppColors.paleInk2)),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('목록을 불러오지 못했어요', style: AppTextStyles.body),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
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
