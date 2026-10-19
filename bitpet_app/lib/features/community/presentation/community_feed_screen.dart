// 07 · 커뮤니티 리스트 — 무한 스크롤 + 서버 카테고리 + 공지 상단 고정
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../notification/providers/notification_provider.dart';
import '../data/models/post_models.dart';
import '../providers/post_provider.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_network_image.dart';

Color _catBg(String? code) => switch (code?.toUpperCase()) {
  'NOTICE' => AppColors.commNoticeBg,
  'FREE' => AppColors.commFreeBg,
  'QNA' => AppColors.commQnaBg,
  'INFO' => AppColors.commInfoBg,
  'ADOPTION' => AppColors.commSellBg,
  _ => AppColors.bgAlt,
};

Color _catInk(String? code) => switch (code?.toUpperCase()) {
  'NOTICE' => AppColors.commNoticeInk,
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

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  bool _showSearch = false;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
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

    // 알림 점은 **안 읽은 알림이 있을 때만** 찍는다. 예전엔 조건 없이 늘 떠 있어서
    // 다 읽어도 빨간 점이 남았다 — 홈 헤더 종과 같은 값을 본다.
    final hasUnread = ref.watch(unreadNotificationCountProvider) > 0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      // ⚠️ 이 화면만 헤더를 손으로 그려 두 줄이었다 — 영문 소제목('community')
      // + 32px 제목. 홈·내 개체·루틴에서 이미 걷어낸 장식이고, 탭을 오가면
      // 제목 크기·위치가 이 화면에서만 튀었다. 다른 탭과 같은 AppBar 로.
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('커뮤니티'),
        titleSpacing: AppSpacing.xl,
        actions: [
          IconButton(
            tooltip: _showSearch ? '검색 닫기' : '제목 검색',
            onPressed: _toggleSearch,
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              size: AppIconSize.lg,
            ),
          ),
          IconButton(
            tooltip: '알림',
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: hasUnread,
              smallSize: 8,
              backgroundColor: AppColors.commNotifDot,
              child: const Icon(
                Icons.notifications_none_outlined,
                size: AppIconSize.lg,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // ── 검색바 (토글) ─────────────────────────────────
          // 손으로 그린 각진 박스였다 — 검색창은 앱 전체가 [AppSearchField] 하나다.
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: AppSearchField(
                value: search,
                hintText: '제목 검색',
                autofocus: true,
                onChanged: (v) =>
                    ref.read(postSearchProvider.notifier).state = v,
              ),
            ),

          // ── 탭 칩 (전체 + 서버 카테고리) ──────────────────
          SizedBox(
            height: AppChip.barHeight,
            child: _buildTabRow(selectedCat, categories),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── 게시글 목록 ──────────────────────────────────
          Expanded(child: _buildBody(feed, search, catById)),
        ],
      ),
      // ── 글쓰기 버튼 (홈 FAB와 동일 위치·크기) ──────────
      // 홈 FAB 와 같은 '만들기' 동작이므로 같은 액션색을 쓴다.
      // 예전엔 primary(먹색)라서 홈은 초록, 커뮤니티는 검정으로 갈려 있었다.
      floatingActionButton: SizedBox(
        width: 50,
        height: 50,
        child: FloatingActionButton(
          heroTag: 'community-compose',
          tooltip: '글쓰기',
          onPressed: () => context.push('/community/new'),
          backgroundColor: AppColors.brandAction,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          child: const Icon(Icons.edit_outlined, size: 24),
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() => _showSearch = !_showSearch);
    if (!_showSearch) {
      ref.read(postSearchProvider.notifier).state = '';
    }
  }

  Widget _buildBody(
    FeedState feed,
    String search,
    Map<int, PostCategory> catById,
  ) {
    if (feed.loading) {
      return const SkeletonCardList();
    }
    if (feed.error != null && feed.posts.isEmpty) {
      return EmptyState(
        message: '불러오지 못했어요',
        subMessage: '연결을 확인하고 다시 시도해주세요.',
        icon: Icons.cloud_off,
        tone: EmptyTone.neutral,
        actionLabel: '다시 시도',
        onAction: () => ref.read(feedProvider.notifier).refresh(),
      );
    }

    final q = search.trim().toLowerCase();
    final filtered = q.isEmpty
        ? feed.posts
        : feed.posts.where((p) => p.title.toLowerCase().contains(q)).toList();

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(feedProvider.notifier).refresh(),
        color: AppColors.brandAction,
        // 당겨서 새로고침이 되려면 스크롤 가능한 자식이어야 한다.
        child: ListView(
          children: [
            SizedBox(
              height: 320,
              child: q.isEmpty
                  ? const EmptyState(
                      message: '아직 게시글이 없어요',
                      subMessage: '첫 글을 작성해보세요',
                      icon: Icons.forum_outlined,
                    )
                  : const EmptyState(
                      message: '검색 결과가 없어요',
                      icon: Icons.search_off,
                      tone: EmptyTone.neutral,
                    ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: AppColors.brandAction,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.only(bottom: 110),
        itemCount: filtered.length + 1,
        itemBuilder: (_, i) {
          if (i == filtered.length) {
            // 하단 로더 / 끝 표시
            if (feed.loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return const SizedBox(height: AppSpacing.sm);
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      itemCount: tabs.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final tab = tabs[i];
        return AppChip(
          label: tab.$2,
          selected: selected == tab.$1,
          onTap: () => ref.read(categoryFilterProvider.notifier).state = tab.$1,
        );
      },
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
    // 글 한 건 = 흰 카드 한 장(2026-10-19). 예전엔 캔버스 위에 줄만 그어 둬서
    // 화면 전체가 회색 한 면으로 보였고, 다른 탭(카드에 내용을 얹는 규칙)과 결이 달랐다.
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: post.isPinned
          // 고정된 글은 연녹 바탕 + 브랜드 테두리로 "맨 위에 있는 최신 글"이 아니라
          // "고정된 글"로 읽히게 한다. 이게 없으면 며칠 지난 공지가 매번 새 글처럼 보인다.
          ? const BoxDecoration(
              color: AppColors.commPinnedBg,
              borderRadius: AppRadius.brLg,
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.brand200),
              ),
            )
          : AppDecor.cardRaised,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                          if (post.isPinned) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.push_pin,
                              size: 16,
                              color: AppColors.ink2,
                            ),
                          ],
                          const Spacer(),
                          Text(
                            _relativeTime(post.createdAt),
                            style: AppTextStyles.monoXs.copyWith(
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        style: AppTextStyles.bodyBold.copyWith(
                          fontSize: 14,
                          color: AppColors.ink,
                          letterSpacing: -0.2,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _AuthorAvatar(
                            imageUrl: post.authorImageUrl,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          // 긴 닉네임이 카드 폭을 넘어 오버플로하지 않게
                          Flexible(
                            child: Text(
                              post.authorName,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '·',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.ink3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _MetaIcon(
                            icon: AppIcons.likeLine,
                            value: post.likeCount,
                          ),
                          const SizedBox(width: 8),
                          _MetaIcon(
                            icon: AppIcons.comment,
                            value: post.commentCount,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '조회 ${post.viewCount}',
                            style: AppTextStyles.monoXs.copyWith(
                              color: AppColors.ink3,
                            ),
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
                      borderRadius: AppRadius.brMd,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: AppNetworkImage(
                      post.thumbnailUrl,
                      fit: BoxFit.cover,
                      memWidth: 300,
                      placeholder: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 28,
                          color: AppColors.ink3,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
        ),
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  /// [AppIcons] 의 SVG 경로. 하트와 말풍선이 한 줄에 붙어 서는 자리라
  /// 한쪽만 Material 로 두면 그 칩만 선 굵기가 달라 보인다.
  final String icon;
  final int value;
  const _MetaIcon({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 16, color: AppColors.ink2),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: AppTextStyles.monoXs.copyWith(color: AppColors.ink2),
        ),
      ],
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  const _AuthorAvatar({required this.imageUrl, this.size = 16});

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
