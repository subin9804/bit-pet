import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pale_palette.dart';
import '../../../pet/data/models/pet_models.dart';

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
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                final key = PalePalette.keyFromHex(pet.colorCode);
                return Positioned(
                  left: i * 22.0,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                          color: bandColor, width: 1.5),
                    ),
                    child: Icon(
                      Icons.pets,
                      size: 14,
                      color: PalePalette.ink(key),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECTED · ${pets.length}',
                  style: AppTextStyles.mono(9, FontWeight.w700,
                      color: AppColors.paleInk2),
                ),
                const SizedBox(height: 2),
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
