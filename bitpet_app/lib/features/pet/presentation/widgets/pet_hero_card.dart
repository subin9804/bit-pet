import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/weight_format.dart';
import '../../data/models/pet_models.dart';
import '../../../../core/theme/app_icons.dart';

/// 개체 상세 최상단 카드.
///
/// ℹ️ 예전엔 개체마다 고른 파스텔색이 이 카드의 바탕이었다. 걷어낸 이유는 **그 색이
/// 아무 정보도 나르지 않았기 때문**이다 — 개체를 만들 때 아무거나 고른 값이라,
/// 화면마다 의미 없는 색이 브랜드색과 서로 당기기만 했다. 개체의 정체성은 사진과
/// 이름이 이미 하고 있다. 안쪽 면들이 `bgAlt` 인 것도 그래서다 (예전엔 파스텔 위에
/// 얹은 반투명 흰색이라, 바탕이 흰색이 되면 통째로 사라진다).
class PetHeroCard extends StatefulWidget {
  final Pet pet;

  const PetHeroCard({super.key, required this.pet});

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
      decoration: AppDecor.card,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                  color: AppColors.bgAlt,
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: pet.profileImageUrl != null
                    ? Image.network(pet.profileImageUrl!, fit: BoxFit.cover)
                    : AppIcon(AppIcons.species(pet.speciesSubcategory),
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
                      color: AppColors.bg,
                      shape: BoxShape.circle,
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
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _copySerial,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _copied
                              ? const Icon(Icons.check_circle_outline,
                                  key: ValueKey('check'),
                                  size: 16,
                                  color: AppColors.brandAction)
                              : const Icon(Icons.copy_outlined,
                                  key: ValueKey('copy'),
                                  size: 16,
                                  color: AppColors.paleInk3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        // 공개만 색을 쓴다 — 비공개가 기본값이라, 둘 다 칠하면
                        // '다름'이 아니라 '배지가 두 종류'로 읽힌다.
                        decoration: BoxDecoration(
                          color: isPublic
                              ? AppColors.brandTint
                              : AppColors.bgAlt,
                          borderRadius: AppRadius.brPill,
                          border: Border.all(
                            color: isPublic
                                ? Colors.transparent
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          isPublic ? '공개' : '비공개',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isPublic
                                ? AppColors.brandTintInk
                                : AppColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
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
                    const SizedBox(width: 8),
                    Text(
                      pet.speciesName.toUpperCase(),
                      style: AppTextStyles.paleSpecies(AppColors.paleInk2),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 성별·체중 pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgAlt,
                    borderRadius: AppRadius.brPill,
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
                          '${formatWeight(pet.latestWeightG!)}g',
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
