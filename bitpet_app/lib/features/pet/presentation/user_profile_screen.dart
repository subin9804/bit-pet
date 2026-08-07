import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/pet_models.dart';
import '../providers/pet_provider.dart';

/// 공개 프로필 — 가계도 카드의 '@닉네임'을 눌렀을 때.
///
/// 목록은 그 사람이 **공개로 둔 개체만** 나온다. 부모로 걸린 개체가 비공개면 여기 없다.
class UserProfileScreen extends ConsumerWidget {
  final int userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userProfileProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      appBar: AppBar(
        backgroundColor: AppColors.paleBg,
        elevation: 0,
        title: const Text('프로필',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('프로필을 불러오지 못했어요',
              style: TextStyle(fontSize: 13, color: AppColors.paleInk3)),
        ),
        data: (profile) => _Body(profile: profile),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final UserProfile profile;
  const _Body({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                border: Border.all(color: AppColors.paleLine),
              ),
              clipBehavior: Clip.hardEdge,
              child: profile.profileImageUrl != null
                  ? Image.network(profile.profileImageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Text('🙂', style: TextStyle(fontSize: 24))))
                  : const Center(child: Text('🙂', style: TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${profile.nickname}',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    profile.isMe
                        ? '내 프로필'
                        : '공개 개체 ${profile.publicPets.length}마리',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('공개 개체',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.paleInk2,
                letterSpacing: 0.4)),
        const SizedBox(height: 8),
        if (profile.publicPets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('공개한 개체가 없어요',
                style: TextStyle(fontSize: 13, color: AppColors.paleInk3)),
          )
        else
          ...profile.publicPets.map((p) => _PublicPetTile(card: p)),
      ],
    );
  }
}

class _PublicPetTile extends StatelessWidget {
  final PetCard card;
  const _PublicPetTile({required this.card});

  Color get _identityColor {
    if (card.colorCode == null) return AppColors.bg2;
    try {
      return Color(int.parse(card.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.bg2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // 내 개체면 전체 상세로, 남의 공개 개체면 공개 화면으로
      onTap: () => context.push(card.isKeeper
          ? '/pets/${card.petId}'
          : '/pets/${card.petId}/public'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.paleLine),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _identityColor,
                border: Border.all(color: AppColors.paleLine),
              ),
              clipBehavior: Clip.hardEdge,
              child: card.profileImageUrl != null
                  ? Image.network(card.profileImageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Text('🦎', style: TextStyle(fontSize: 20))))
                  : const Center(child: Text('🦎', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    card.morphLabel.isEmpty
                        ? card.speciesName
                        : '${card.speciesName} · ${card.morphLabel}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
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
