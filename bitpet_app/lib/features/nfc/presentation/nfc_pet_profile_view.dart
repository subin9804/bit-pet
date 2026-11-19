import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/weight_format.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/stat_card.dart';
import '../../pet/data/models/photo_models.dart';
import '../../pet/presentation/widgets/gallery_photo_viewer.dart';
import '../../pet/presentation/widgets/pet_hero_card.dart';
import '../data/models/tag_models.dart';

/// 남의 개체 이름표를 찍었을 때의 프로필 — 히어로 + 최근 체중 + 갤러리만.
///
/// 비공개 개체도 열린다 (실물 이름표가 있어야 닿는 경로). 무엇을 보여줄지는
/// 서버가 응답에서 이미 정했다 — 기록·체중 이력·소유자는 여기 오지도 않는다.
/// 이 화면은 받은 걸 그리기만 하고, 대표 설정·삭제·업로드 같은 동작은 없다.
class NfcPetProfileView extends StatelessWidget {
  final NfcPetProfile profile;

  const NfcPetProfileView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final photos = profile.photos;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, 0),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.md),
            child: Text('갤러리', style: AppTextStyles.h3),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
            child: photos.isEmpty
                ? Container(
                    width: double.infinity,
                    decoration: AppDecor.cardRaised,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: const EmptyState(
                      icon: Icons.photo_library_outlined,
                      message: '아직 사진이 없어요',
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (_, i) => _Tile(
                      photo: photos[i],
                      onTap: () => GalleryPhotoViewer.show(
                        context,
                        photos: photos,
                        initialIndex: i,
                        readOnly: true,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 갤러리 탭의 타일과 같은 모양(둥근 모서리·축소본) — 대표 별·롱프레스 메뉴만 없다.
class _Tile extends StatelessWidget {
  final PetPhoto photo;
  final VoidCallback onTap;

  const _Tile({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: AppNetworkImage(
          photo.displayUrl,
          fit: BoxFit.cover,
          memWidth: 400,
          placeholder: Container(
            color: AppColors.bgAlt,
            child: const AppIcon(AppIcons.petLine,
                color: AppColors.ink3, size: 28),
          ),
        ),
      ),
    );
  }
}
