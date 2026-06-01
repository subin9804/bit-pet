import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pale_palette.dart';
import '../../data/models/pet_models.dart';

class PetHeroCard extends StatelessWidget {
  final Pet pet;
  final PetPaletteKey paletteKey;

  const PetHeroCard({super.key, required this.pet, required this.paletteKey});

  @override
  Widget build(BuildContext context) {
    final bg = PalePalette.pale(paletteKey);
    final genderSymbol = switch (pet.gender) {
      'MALE'   => '♂',
      'FEMALE' => '♀',
      _        => '?',
    };
    final genderLabel = switch (pet.gender) {
      'MALE'   => '수컷',
      'FEMALE' => '암컷',
      _        => '미확인',
    };

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 아바타 박스 92×92
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(22),
            ),
            child: pet.profileImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Image.network(pet.profileImageUrl!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.pets, color: AppColors.primary, size: 44),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 종명 (영문 대문자, JetBrains Mono)
                Text(
                  pet.speciesName.toUpperCase(),
                  style: AppTextStyles.paleSpecies(AppColors.paleInk2),
                ),
                const SizedBox(height: 4),
                // 개체명
                Text(
                  pet.name,
                  style: AppTextStyles.paleHero(AppColors.primary),
                ),
                const SizedBox(height: 8),
                // 성별·체중 pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$genderSymbol $genderLabel',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (pet.latestWeightG != null) ...[
                        Text(
                          ' · ',
                          style: TextStyle(fontSize: 11, color: AppColors.paleInk2),
                        ),
                        Text(
                          '${pet.latestWeightG!.toStringAsFixed(0)}g',
                          style: AppTextStyles.mono(11, FontWeight.w700),
                        ),
                      ],
                    ],
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
