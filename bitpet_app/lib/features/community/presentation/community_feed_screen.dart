// 07 · 커뮤니티 리스트 — PALE 디자인 핸드오프 반영
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/post_models.dart';
import '../providers/post_provider.dart';

const _kTabs = [
  (null, '전체'),
  ('free', '자유'),
  ('qna', 'QnA'),
  ('info', '정보'),
  ('sell', '분양'),
];

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

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(categoryFilterProvider);
    final feedAsync = ref.watch(feedProvider);
    final search = ref.watch(postSearchProvider);

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
                      // 검색 버튼
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
                      // 알림 버튼
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
                        borderRadius: BorderRadius.circular(12),
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

                // ── 탭 칩 ─────────────────────────────────────────
                SizedBox(
                  height: 44,
                  child: feedAsync.when(
                    loading: () => _buildTabRow(selectedTab, {}, ref),
                    error: (_, __) => _buildTabRow(selectedTab, {}, ref),
                    data: (posts) {
                      final counts = <String?, int>{null: posts.length};
                      for (final t in _kTabs.skip(1)) {
                        counts[t.$1] = posts
                            .where((p) =>
                                p.categoryCode.toLowerCase() == t.$1)
                            .length;
                      }
                      return _buildTabRow(selectedTab, counts, ref);
                    },
                  ),
                ),

                // ── 구분선 ───────────────────────────────────────
                Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.paleLine.withAlpha(128)),

                // ── 게시글 목록 ──────────────────────────────────
                Expanded(
                  child: feedAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('불러오기 실패',
                              style: AppTextStyles.bodyBold
                                  .copyWith(color: AppColors.paleInk2)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                ref.read(feedProvider.notifier).load(),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                    data: (posts) {
                      final q = search.trim().toLowerCase();
                      final filtered = posts.where((p) {
                        final tabMatch = selectedTab == null ||
                            p.categoryCode.toLowerCase() == selectedTab;
                        final searchMatch =
                            q.isEmpty || p.title.toLowerCase().contains(q);
                        return tabMatch && searchMatch;
                      }).toList();

                      final pinned = filtered.where((p) => p.isPinned).toList();
                      final normal = filtered.where((p) => !p.isPinned).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('아직 게시글이 없어요',
                                  style: AppTextStyles.bodyBold
                                      .copyWith(color: AppColors.paleInk2)),
                              const SizedBox(height: 4),
                              Text('첫 글을 작성해보세요',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.paleInk3)),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(feedProvider.notifier).load(),
                        color: AppColors.primary,
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 110),
                          children: [
                            if (pinned.isNotEmpty) ...[
                              ColoredBox(
                                color: AppColors.commPinnedBg
                                    .withAlpha(200),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          22, 8, 22, 4),
                                      child: Text(
                                        '📌 PINNED',
                                        style: AppTextStyles.monoXs.copyWith(
                                          color: AppColors.paleInk2,
                                          letterSpacing: 0.4,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    ...pinned.map((p) => _PostRow(
                                          post: p,
                                          onTap: () =>
                                              context.push('/community/${p.id}'),
                                        )),
                                  ],
                                ),
                              ),
                              Divider(
                                  height: 1,
                                  color: AppColors.paleLineSoft),
                            ],
                            ...normal.map((p) => _PostRow(
                                  post: p,
                                  onTap: () =>
                                      context.push('/community/${p.id}'),
                                )),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── 플로팅 글쓰기 버튼 ────────────────────────────────
            Positioned(
              right: 18,
              bottom: 80,
              child: GestureDetector(
                onTap: () => context.push('/community/new'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x403A332B),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: AppColors.paleBg, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabRow(
      String? selected, Map<String?, int> counts, WidgetRef ref) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      itemCount: _kTabs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (_, i) {
        final tab = _kTabs[i];
        final active = selected == tab.$1;
        final count = counts[tab.$1] ?? 0;
        return GestureDetector(
          onTap: () =>
              ref.read(categoryFilterProvider.notifier).state = tab.$1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.card,
              border: Border.all(
                color: active ? Colors.transparent : AppColors.paleLine,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tab.$2,
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 13,
                    color: active ? AppColors.paleBg : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: AppTextStyles.monoXs.copyWith(
                    fontWeight: FontWeight.w700,
                    color: active
                        ? AppColors.paleBg.withAlpha(153)
                        : AppColors.paleInk3,
                  ),
                ),
              ],
            ),
          ),
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
  final VoidCallback onTap;
  const _PostRow({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = post.categoryCode.toLowerCase();

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
            // 좌측 본문
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 태그 + HOT + 시각
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
                      const Spacer(),
                      Text(
                        _relativeTime(post.createdAt),
                        style: AppTextStyles.monoXs
                            .copyWith(color: AppColors.paleInk3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 제목
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
                  // 메타: 작성자 · 좋아요 · 댓글 · 조회
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
            const SizedBox(width: 12),
            // 우측 썸네일
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _catBg(cat).withAlpha(216),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.image_outlined,
                    size: 28, color: AppColors.paleInk3),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _catBg(cat),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _catLabel(cat),
        style: AppTextStyles.monoXs.copyWith(
          color: _catInk(cat),
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
