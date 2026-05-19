import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/post_provider.dart';

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  static const _categories = [
    (null, '전체'),
    ('FREE', '자유'),
    ('QNA', 'Q&A'),
    ('INFO', '정보'),
    ('ADOPTION', '분양'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(categoryFilterProvider);
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/community/new'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = selectedCategory == cat.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.$2),
                    selected: isSelected,
                    onSelected: (_) => ref
                        .read(categoryFilterProvider.notifier)
                        .state = cat.$1,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: feedAsync.when(
        loading: () => const SkeletonCardList(),
        error: (e, _) => EmptyState(
          message: '불러오기 실패',
          subMessage: e.toString(),
          actionLabel: '다시 시도',
          onAction: () => ref.read(feedProvider.notifier).load(),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const EmptyState(
              message: '게시글이 없어요',
              subMessage: '첫 번째 게시글을 작성해보세요!',
              icon: Icons.article_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(feedProvider.notifier).load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final post = posts[i];
                return GestureDetector(
                  onTap: () => context.push('/community/${post.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _CategoryBadge(code: post.categoryCode),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(post.title,
                                  style: AppTextStyles.bodyBold,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(post.content,
                            style: AppTextStyles.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(post.authorName, style: AppTextStyles.caption),
                            const Spacer(),
                            Icon(Icons.favorite_outline,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Text('${post.likeCount}',
                                style: AppTextStyles.caption),
                            const SizedBox(width: 12),
                            Icon(Icons.chat_bubble_outline,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Text('${post.commentCount}',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/community/new'),
        child: const Icon(Icons.edit_outlined),
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

  Color get color => switch (code) {
        'FREE' => AppColors.primary,
        'QNA' => AppColors.info,
        'INFO' => AppColors.secondary,
        'ADOPTION' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.label.copyWith(color: color)),
    );
  }
}
