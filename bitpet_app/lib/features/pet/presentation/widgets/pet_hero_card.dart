import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pale_palette.dart';
import '../../data/models/pet_models.dart';

class PetHeroCard extends StatefulWidget {
  final Pet pet;
  final PetPaletteKey paletteKey;

  const PetHeroCard({super.key, required this.pet, required this.paletteKey});

  @override
  State<PetHeroCard> createState() => _PetHeroCardState();
}

class _PetHeroCardState extends State<PetHeroCard> {
  bool _copied = false;

  Future<void> _copySerial() async {
    await Clipboard.setData(ClipboardData(text: widget.pet.serialNo));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final bg = PalePalette.pale(widget.paletteKey);
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
    final isPublic = pet.privateYn == 'N';

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 아바타 박스 92×92 (+ 이별 시 우측 하단 무지개 배지)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  border: Border.all(color: AppColors.border),
                ),
                child: pet.profileImageUrl != null
                    ? Image.network(pet.profileImageUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.pets,
                        color: AppColors.primary, size: 44),
              ),
              if (pet.isDeceased)
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text('🌈', style: TextStyle(fontSize: 13)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 일련번호 + 공개여부
                if (pet.serialNo.isNotEmpty)
                  Row(
                    children: [
                      Text(
                        pet.serialNo,
                        style: AppTextStyles.mono(10, FontWeight.w700).copyWith(
                          color: AppColors.paleInk2,
                        ),
                      ),
                      const SizedBox(width: 3),
                      GestureDetector(
                        onTap: _copySerial,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _copied
                              ? const Icon(Icons.check_circle_outline,
                                  key: ValueKey('check'),
                                  size: 12,
                                  color: AppColors.petSageInk)
                              : const Icon(Icons.copy_outlined,
                                  key: ValueKey('copy'),
                                  size: 12,
                                  color: AppColors.paleInk3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPublic
                              ? AppColors.petSage
                              : Colors.white.withValues(alpha: 0.45),
                          border: Border.all(
                            color: isPublic
                                ? AppColors.petSageInk.withValues(alpha: 0.3)
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          isPublic ? '공개' : '비공개',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isPublic
                                ? AppColors.petSageInk
                                : AppColors.paleInk2,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 3),
                // 이름 + 종이름
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        pet.name,
                        style: AppTextStyles.paleHero(AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      pet.speciesName.toUpperCase(),
                      style: AppTextStyles.paleSpecies(AppColors.paleInk2),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 성별·체중 pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    border: Border.all(color: AppColors.border),
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
