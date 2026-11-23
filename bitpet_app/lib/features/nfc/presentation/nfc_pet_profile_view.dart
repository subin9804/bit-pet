import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/weight_format.dart';
import '../../../core/widgets/stat_card.dart';
import '../../pet/presentation/widgets/pet_hero_card.dart';
import '../../pet/data/models/pet_models.dart';
import '../data/models/tag_models.dart';

/// 남의 개체 이름표를 찍었을 때의 프로필 — 히어로 + 최근 체중만.
///
/// 비공개 개체도 열린다 (실물 이름표가 있어야 닿는 경로). 무엇을 보여줄지는
/// 서버가 응답에서 이미 정했다 — 갤러리·기록·체중 이력은 여기 오지도 않는다.
/// 소유자 줄을 누르면 그 사람 프로필로 간다 (2026-11-23). 닉네임을 감춘 사람·차단 관계면
/// 서버가 userId 를 비워 보내 "비공개"로만 보이고 눌리지 않는다.
/// (갤러리는 한때 그렸다가 뺐다 — 대표사진 한 장이면 충분하다는 판단.)
class NfcPetProfileView extends StatelessWidget {
  final NfcPetProfile profile;

  const NfcPetProfileView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.brandTintSoft,
        titleSpacing: 0,
        // 딥링크로 들어온 화면이라 스택 아래가 비어 있다 — 닫으면 홈으로
        leading: IconButton(
          tooltip: '닫기',
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('이름표'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.brandTintSoft,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 44),
            child: PetHeroCard.card(card: profile.pet),
          ),
          // 개체 상세처럼 밴드에 걸치는 통계 칸 — 남에게는 최근 체중 하나만.
          // 이력·그래프는 기록이라 서버가 내려주지 않는다.
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: StatCardRow(cards: [
                StatCard(
                  label: '최근 체중',
                  value: profile.latestWeightG == null
                      ? null
                      : formatWeight(profile.latestWeightG!),
                  unit: 'g',
                ),
              ]),
            ),
          ),
          // Transform 은 레이아웃 높이를 줄이지 않아 위로 28px 이 이미 비어 있다
          if (profile.owner case final owner? when !owner.isOrphaned)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
              child: _OwnerTile(owner: owner),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
            child: Row(
              children: [
                const Icon(Icons.lock_outline,
                    size: AppIconSize.badge, color: AppColors.ink3),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '다른 사육자의 개체예요. 사육 기록은 보이지 않아요.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.ink3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 사육자 한 줄. 프로필로 갈 수 있을 때만 눌린다.
class _OwnerTile extends StatelessWidget {
  final PetOwner owner;
  const _OwnerTile({required this.owner});

  @override
  Widget build(BuildContext context) {
    final userId = owner.userId;
    final canOpen = userId != null && !owner.isMe;
    return Container(
      decoration: AppDecor.cardRaised,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: canOpen ? () => context.push('/users/$userId') : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Text('사육자', style: AppTextStyles.caption),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    owner.nickname ?? '비공개',
                    style: AppTextStyles.bodyBold.copyWith(
                        color: canOpen ? AppColors.ink : AppColors.ink3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canOpen) ...[
                  Text('프로필 보기',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.brandAction)),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.brandAction),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
