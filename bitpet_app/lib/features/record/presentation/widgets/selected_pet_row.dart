import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pet_avatar.dart';
import '../../../pet/data/models/pet_models.dart';
import '../../../../core/theme/app_dimens.dart';

/// 선택된 개체 요약 행.
/// 급여 밴드색 배경, 겹침 아바타(최대 5개) + "SELECTED·N" + 이름 join.
class SelectedPetRow extends StatelessWidget {
  final List<Pet> pets;
  final Color? bg; // 기본값: AppColors.feedBand

  const SelectedPetRow({super.key, required this.pets, this.bg});

  @override
  Widget build(BuildContext context) {
    final bandColor = bg ?? AppColors.feedBand;

    return Container(
      decoration: BoxDecoration(
        color: bandColor,
        borderRadius: AppRadius.brMd,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // 겹침 아바타 (최대 5개, -8px overlap)
          SizedBox(
            width: _avatarWidth(pets.length.clamp(0, 5)),
            height: 30,
            child: Stack(
              children: pets.take(5).toList().asMap().entries.map((e) {
                final i   = e.key;
                final pet = e.value;
                return Positioned(
                  left: i * 22.0,
                  child: PetAvatar(
                    imageUrl: pet.profileImageUrl,
                    size: 30,
                    // 밴드색(급여·체중 등 기록 종류)은 남긴다 — 그건 정보다.
                    // 개체별 색만 걷어냈으므로 아바타는 전부 같은 중립색이다.
                    background: AppColors.bg,
                    iconColor: AppColors.ink2,
                    border: Border.all(color: bandColor, width: 1.5),
                    subcategory: pet.speciesSubcategory,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECTED · ${pets.length}',
                  style: AppTextStyles.mono(9, FontWeight.w700,
                      color: AppColors.paleInk2),
                ),
                const SizedBox(height: 4),
                Text(
                  pets.map((p) => p.name).join(' · '),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5개 겹침 아바타의 전체 폭 계산
  static double _avatarWidth(int count) {
    if (count == 0) return 0;
    return 30 + (count - 1) * 22.0;
  }
}
