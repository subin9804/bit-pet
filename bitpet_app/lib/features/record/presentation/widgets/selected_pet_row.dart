import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pet_avatar.dart';
import '../../../pet/data/models/pet_models.dart';
import '../../../../core/theme/app_dimens.dart';

/// 선택된 개체 요약 행 — 겹침 아바타(최대 5개) + "대상 N" + 이름 join.
///
/// ⛔ **면 전체를 분류색으로 칠하지 말 것.** 2026-10-14 이전에는 바탕이
/// `feedBand`(= `petPeach`, 복숭아빛 분홍)였다. 급여 기록 어느 단계에서나
/// 화면 상단에 분홍 블록이 깔려서, 저채도 리뉴얼 테마 위에 **예전 디자인이
/// 한 장 남은 것처럼** 보였다 (사용자 지적). 분류색은 '종류 표시 전용'이라
/// 점·칩 크기까지가 한계다 — 그래서 바탕은 흰 카드로 바꾸고 색은 왼쪽
/// [tint] 점 하나로만 남긴다.
///
/// [tint] 를 주지 않으면 점도 찍지 않는다 (종류가 하나뿐인 자리).
class SelectedPetRow extends StatelessWidget {
  final List<Pet> pets;

  /// 기록 종류색(`AppColors.catFeed` 등). 점 하나로만 쓰인다.
  final Color? tint;

  const SelectedPetRow({super.key, required this.pets, this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecor.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          if (tint != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
          ],
          // 겹침 아바타 (최대 5개, -8px overlap)
          SizedBox(
            width: _avatarWidth(pets.length.clamp(0, 5)),
            height: 30,
            child: Stack(
              children: pets.take(5).toList().asMap().entries.map((e) {
                final i = e.key;
                final pet = e.value;
                return Positioned(
                  left: i * 22.0,
                  child: PetAvatar(
                    imageUrl: pet.profileImageUrl,
                    size: 30,
                    background: AppColors.bgAlt,
                    iconColor: AppColors.ink2,
                    // 테두리는 **바탕색**이다 — 겹친 아바타를 떼어 보이게 하는
                    // 것이 목적이라 바탕이 흰 카드가 된 지금은 흰색이어야 한다.
                    border: Border.all(color: AppColors.card, width: 1.5),
                    subcategory: pet.speciesSubcategory,
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
                // 'SELECTED · N' 이던 자리. 영문 모노 라벨이 화면마다 박혀 있는
                // 게 '예전 디자인'으로 읽힌다는 지적이라 한글 한 줄로 줄였다.
                Text(
                  '대상 ${pets.length}',
                  style: AppTextStyles.label.copyWith(color: AppColors.ink3),
                ),
                const SizedBox(height: 2),
                Text(
                  pets.map((p) => p.name).join(' · '),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
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
