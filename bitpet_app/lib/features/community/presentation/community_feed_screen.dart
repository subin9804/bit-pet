// 07 · 커뮤니티 리스트 — 무한 스크롤 + 서버 카테고리 + 공지 상단 고정
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_chip.dart';
import '../data/models/post_models.dart';
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

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCat = ref.watch(categoryFilterProvider);
    final feed = ref.watch(feedProvider);
    final search = ref.watch(postSearchProvider);
    // 라벨/색상 해석은 전체 카테고리로, 탭 노출은 visible(INFO·분양 제외)만
    final allCategories =
        ref.watch(categoriesProvider).valueOrNull ?? const <PostCategory>[];
    final catById = {for (final c in allCategories) c.id: c};
    final categories = ref.watch(visibleCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ── 헤더 ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'community',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 11,
                              color: AppColors.paleInk2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '커뮤니티',
                            style: AppTextStyles.h1.copyWith(
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _CircleBtn(
                        onTap: () {
                          setState(() => _showSearch = !_showSearch);
                          if (!_showSearch) {
                            _searchCtrl.clear();
                            ref.read(postSearchProvider.notifier).state = '';
                          }
                        },
                        child: const Icon(Icons.search_rounded,
                            size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _CircleBtn(
                            onTap: () => context.push('/notifications'),
                            child: const Icon(Icons.notifications_none_rounded,
                                size: 18, color: AppColors.primary),
                          ),
                          Positioned(
                            top: 8,
                            right: 10,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.commNotifDot,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 검색바 (토글) ─────────────────────────────────
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.paleLine),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.primary),
                        decoration: InputDecoration(
                          hintText: '제목 검색…',
                          hintStyle: AppTextStyles.body
                              .copyWith(color: AppColors.paleInk3),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 18, color: AppColors.paleInk3),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onChanged: (v) =>
                            ref.read(postSearchProvider.notifier).state = v,
                      ),
                    ),
                  ),

                // ── 탭 칩 (전체 + 서버 카테고리) ──────────────────
                SizedBox(
                  height: AppChip.barHeight,
                  child: _buildTabRow(selectedCat, categories),
                ),

                const SizedBox(height: 8),

                // ── 게시글 목록 ──────────────────────────────────
                Expanded(
                  child: _buildBody(feed, search, catById),
                ),
              ],
            ),

            // ── 플로팅 글쓰기 버튼 (홈 FAB와 동일 위치·크기) ──────────
            Positioned(
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () => context.push('/community/new'),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: AppColors.paleBg, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      FeedState feed, String search, Map<int, PostCategory> catById) {
    if (feed.loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (feed.error != null && feed.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('불러오기 실패',
                style: AppTextStyles.bodyBold
                    .copyWith(color: AppColors.paleInk2)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(feedProvider.notifier).refresh(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final q = search.trim().toLowerCase();
    final filtered = q.isEmpty
        ? feed.posts
        : feed.posts
            .where((p) => p.title.toLowerCase().contains(q))
            .toList();

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(feedProvider.notifier).refresh(),
        color: AppColors.primary,
        child: ListView(
          children: [
            SizedBox(
              height: 260,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(q.isEmpty ? '아직 게시글이 없어요' : '검색 결과가 없어요',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.paleInk2)),
                    const SizedBox(height: 4),
                    if (q.isEmpty)
                      Text('첫 글을 작성해보세요',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.paleInk3)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.only(bottom: 110),
        itemCount: filtered.length + 1,
        itemBuilder: (_, i) {
          if (i == filtered.length) {
            // 하단 로더 / 끝 표시
            if (feed.loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return const SizedBox(height: 8);
          }
          final p = filtered[i];
          return _PostRow(
            post: p,
            code: catById[p.categoryId]?.code,
            label: catById[p.categoryId]?.nameKo ?? '',
            onTap: () => context.push('/community/${p.id}'),
          );
        },
      ),
    );
  }

  Widget _buildTabRow(int? selected, List<PostCategory> categories) {
    // [전체(null)] + 서버 카테고리
    final tabs = <(int?, String)>[
      (null, '전체'),
      ...categories.map((c) => (c.id, c.nameKo)),
    ];
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      itemCount: tabs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (_, i) {
        final tab = tabs[i];
        return AppChip(
          label: tab.$2,
          selected: selected == tab.$1,
          onTap: () =>
              ref.read(categoryFilterProvider.notifier).state = tab.$1,
        );
      },
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _CircleBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.paleLine),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _PostRow extends StatelessWidget {
  final Post post;
  final String? code;
  final String label;
  final VoidCallback onTap;
  const _PostRow({
    required this.post,
    required this.code,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.paleLineSoft),
          ),
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
                      _CategoryPill(code: code, label: label),
                      const Spacer(),
                      Text(
                        _relativeTime(post.createdAt),
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
                      letterSpacing: -0.2,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(post.authorName,
                          style: AppTextStyles.caption
                              .copyWith(fontSize: 11)),
                      const SizedBox(width: 6),
                      Text('·',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.paleInk3)),
                      const SizedBox(width: 6),
                      _MetaIcon(
                          icon: Icons.favorite_outline,
                          value: post.likeCount),
                      const SizedBox(width: 10),
                      _MetaIcon(
                          icon: Icons.chat_bubble_outline,
                          value: post.commentCount),
                      const SizedBox(width: 10),
                      Text(
                        '조회 ${post.viewCount}',
                        style: AppTextStyles.monoXs
                            .copyWith(color: AppColors.paleInk3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 썸네일 — 사진이 있는 게시글만 표시
            if (post.thumbnailUrl != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _catBg(code).withAlpha(216),
                  borderRadius: BorderRadius.zero,
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  post.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.image_outlined,
                        size: 28, color: AppColors.paleInk3),
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

class _CategoryPill extends StatelessWidget {
  final String? code;
  final String label;
  const _CategoryPill({required this.code, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _catBg(code),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label,
        style: AppTextStyles.monoXs.copyWith(
          color: _catInk(code),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  final IconData icon;
  final int value;
  const _MetaIcon({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.paleInk2),
        const SizedBox(width: 3),
        Text(
          '$value',
          style: AppTextStyles.monoXs.copyWith(color: AppColors.paleInk2),
        ),
      ],
    );
  }
}
