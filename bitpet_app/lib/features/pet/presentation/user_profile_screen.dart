import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../community/providers/post_provider.dart';
import '../../my/presentation/my_activity_screen.dart';
import '../data/models/pet_models.dart';
import '../providers/pet_provider.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_network_image.dart';

/// 공개 프로필 — 가계도 카드의 '@닉네임', 커뮤니티 작성자 닉네임을 눌렀을 때.
///
/// 탭 셋: **개체**(그 사람이 공개로 둔 것만) · **글** · **댓글**.
/// 글·댓글 탭은 마이페이지 '내 게시글'과 같은 목록 위젯을 쓴다 — 서버가 보는 사람 기준으로
/// 차단·어린이 게시판·원글 삭제를 이미 걸러서 내린다.
///
/// 가계도 닉네임을 숨긴 사람은 개체 목록이 비어 온다(`petsHidden`). 차단 관계면 화면 자체가 열리지 않는다.
class UserProfileScreen extends ConsumerStatefulWidget {
  final int userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(userProfileProvider(widget.userId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        titleSpacing: 0,
        title: const Text('프로필'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.person_off_outlined,
          tone: EmptyTone.neutral,
          message: serverMessageOf(e) ?? '프로필을 불러오지 못했어요',
        ),
        data: (profile) => Column(
          children: [
            _Header(profile: profile),
            TabBar(
              controller: _tab,
              labelColor: AppColors.brandAction,
              unselectedLabelColor: AppColors.ink3,
              indicatorColor: AppColors.brandAction,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppTextStyles.bodyBold,
              unselectedLabelStyle: AppTextStyles.body,
              tabs: const [
                Tab(text: '개체'),
                Tab(text: '작성한 글'),
                Tab(text: '작성한 댓글'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _PetsTab(profile: profile),
                  PostsListTab(
                    provider: userPostsProvider(widget.userId),
                    emptySubMessage: null,
                  ),
                  CommentsListTab(
                    provider: userCommentsProvider(widget.userId),
                    emptySubMessage: null,
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

class _Header extends StatelessWidget {
  final PublicUserProfile profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecor.cardRaised,
      child: Row(
        children: [
          UserAvatar(
            imageUrl: profile.profileImageUrl,
            colorKey: profile.profileColor,
            size: 56,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.nickname,
                  style: AppTextStyles.heading.copyWith(color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.isMe
                      ? '내 프로필'
                      : profile.petsHidden
                          ? '개체 비공개'
                          : '공개 개체 ${profile.publicPets.length}마리',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetsTab extends StatelessWidget {
  final PublicUserProfile profile;
  const _PetsTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.petsHidden) {
      return const EmptyState(
        icon: Icons.lock_outline,
        tone: EmptyTone.neutral,
        message: '개체를 공개하지 않은 사용자예요',
      );
    }
    if (profile.publicPets.isEmpty) {
      return const EmptyState(
        icon: Icons.pets_outlined,
        message: '공개한 개체가 없어요',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final p in profile.publicPets) _PublicPetTile(card: p),
      ],
    );
  }
}

class _PublicPetTile extends StatelessWidget {
  final PetCard card;
  const _PublicPetTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final speciesIcon = Center(
        child: AppIcon(AppIcons.species(card.speciesSubcategory),
            size: 20, color: AppColors.ink2));
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: AppDecor.cardRaised,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          // 내 개체면 전체 상세로, 남의 공개 개체면 공개 화면으로
          onTap: () => context.push(card.isKeeper
              ? '/pets/${card.petId}'
              : '/pets/${card.petId}/public'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    borderRadius: AppRadius.brMd,
                    color: AppColors.bgAlt,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: card.profileImageUrl != null
                      ? AppNetworkImage(card.profileImageUrl,
                          fit: BoxFit.cover,
                          memWidth: 120,
                          placeholder: speciesIcon)
                      : speciesIcon,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.name,
                          style: AppTextStyles.bodyBold
                              .copyWith(color: AppColors.ink),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        card.morphLabel.isEmpty
                            ? card.speciesName
                            : '${card.speciesName} · ${card.morphLabel}',
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
