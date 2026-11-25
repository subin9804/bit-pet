import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pet_avatar.dart';
import '../../../pet/data/models/pet_models.dart';

// 기록 폼 부품 — FAB 기록 시트와 기록 상세의 추가/수정 시트가 **같이 쓴다**.
// 원래 FAB 안에만 있어서 기록 상세 쪽은 비슷하게 따로 그렸고, 같은 메이팅 기록을
// 두 모양으로 적게 됐다(2026-11-26 사용자 지적). 한쪽만 고치지 말 것.

/// 칸 제목 — 필수는 빨간 *, 선택은 '(선택)'.
class RecordFieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const RecordFieldLabel(this.label, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700, color: AppColors.error)),
        ] else ...[
          const SizedBox(width: 8),
          Text('(선택)', style: AppTextStyles.label),
        ],
      ],
    );
  }
}

/// 하나만 고르는 토글 버튼 (내 개체/외부 개체, 결과 미정/성공/실패 등).
class RecordToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const RecordToggle({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.brandAction : AppColors.card,
          border: Border.all(
              color: active ? AppColors.brandAction : AppColors.line,
              width: active ? 1.5 : 1),
          borderRadius: AppRadius.brMd,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: active ? AppColors.card : AppColors.ink2)),
      ),
    );
  }
}

/// 일련번호로 찾은 외부 파트너.
class PartnerResultCard extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? imageUrl;
  final String? subcategory;
  final VoidCallback onClear;

  const PartnerResultCard({
    super.key,
    required this.name,
    required this.onClear,
    this.subtitle,
    this.imageUrl,
    this.subcategory,
  });

  PartnerResultCard.pet({super.key, required Pet pet, required this.onClear})
      : name = pet.name,
        subtitle = '${pet.speciesName} · ${pet.serialNo}',
        imageUrl = pet.profileImageUrl,
        subcategory = pet.speciesSubcategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppDecor.cardSelected,
      child: Row(
        children: [
          PetAvatar(
            imageUrl: imageUrl,
            size: 36,
            background: AppColors.bg,
            iconColor: AppColors.brandAction,
            subcategory: subcategory,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: AppColors.ink2),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 20, color: AppColors.ink3),
          ),
        ],
      ),
    );
  }
}
