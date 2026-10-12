import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/pet_models.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_network_image.dart';

/// 개체 상세 최상단 — 연녹 밴드 위에 **카드 없이** 바로 놓이는 소개 줄.
///
/// ⚠️ 한때 이 자리를 흰 카드로 감쌌다가 되돌렸다. 바로 아래 통계 3칸이
/// 밴드 경계에 걸치는 흰 카드라, 흰 카드가 둘이 되면 밴드가 그냥 **카드
/// 사이의 빈틈**으로 보인다. 밴드 위에 글씨와 작은 칩만 떠 있고 카드는
/// 통계 하나뿐이어야 "개체의 공간 → 내용"으로 읽힌다.
///
/// ℹ️ 예전엔 개체마다 고른 파스텔색이 이 영역의 바탕이었다. 걷어낸 이유는 **그 색이
/// 아무 정보도 나르지 않았기 때문**이다 — 개체를 만들 때 아무거나 고른 값이라,
/// 화면마다 의미 없는 색이 브랜드색과 서로 당기기만 했다. 개체의 정체성은 사진과
/// 이름이 이미 하고 있다.
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
    final genderColor = switch (pet.gender) {
      'MALE'   => AppColors.petSkyInk,
      'FEMALE' => AppColors.petPeachInk,
      _        => AppColors.ink3,
    };
    final isPublic = pet.privateYn == 'N';

    // 종 한 줄. 모프를 뒤에 이어 붙여 두었다가 **상세 정보 카드 맨 아래로 내렸다** —
    // 같은 값이 두 곳에 있었고, 모프가 많은 개체는 이 줄이 통째로 잘렸다.
    final subtitle = pet.speciesName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 아바타 — 연녹 밴드 위의 **흰 원**. 네모 썸네일이면 밴드 위에
        // 떠 있는 또 하나의 작은 카드처럼 보인다.
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.bg,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: pet.profileImageUrl != null
                  ? AppNetworkImage(pet.profileImageUrl,
                      fit: BoxFit.cover, memWidth: 400)
                  : AppIcon(AppIcons.species(pet.speciesSubcategory),
                      color: AppColors.brandIcon, size: 40),
            ),
            if (pet.isDeceased)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Text('🌈', style: TextStyle(fontSize: 14)),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이름 + 성별 기호
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      pet.name,
                      style: AppTextStyles.paleHero(AppColors.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // 성별은 이름 옆 기호 하나로 — 아래 칩에 글자로도 있지만,
                  // 이름 줄에서 바로 보이는 쪽이 먼저 읽힌다.
                  Text(genderSymbol,
                      style: AppTextStyles.subheading
                          .copyWith(fontWeight: FontWeight.w700, color: genderColor)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // 종 · 모프
              Text(
                subtitle,
                style: AppTextStyles.sub.copyWith(color: AppColors.ink2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),

              // 작은 흰 칩 — 밴드 위라 흰 면만으로 충분히 떠 보인다.
              //
              // 밴드에 남기는 값은 **개체 코드와 공개 여부 둘뿐**이다. 성별은 이름
              // 옆 기호가 이미 말하고, 체중은 바로 아래 통계 카드에 숫자로 있다 —
              // 칩으로 또 쓰면 한 화면에서 같은 값을 두 번 읽게 된다.
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  // 개체 코드. 탭하면 그대로 복사된다.
                  if (pet.serialNo.isNotEmpty)
                    _HeroChip(
                      onTap: _copySerial,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pet.serialNo,
                            style: AppTextStyles.mono(10, FontWeight.w700)
                                .copyWith(color: AppColors.ink2),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _copied
                                ? const Icon(Icons.check_circle_outline,
                                    key: ValueKey('check'),
                                    size: AppIconSize.badge,
                                    color: AppColors.brandAction)
                                : const Icon(Icons.copy_outlined,
                                    key: ValueKey('copy'),
                                    size: AppIconSize.badge,
                                    color: AppColors.ink3),
                          ),
                        ],
                      ),
                    ),
                  // 공개만 색을 쓴다 — 비공개가 기본값이라, 둘 다 칠하면
                  // '다름'이 아니라 '배지가 두 종류'로 읽힌다.
                  _HeroChip(
                    tinted: isPublic,
                    child: Text(
                      isPublic ? '공개' : '비공개',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color:
                            isPublic ? AppColors.brandTintInk : AppColors.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 밴드 위에 올라가는 작은 칩. 테두리를 두지 않는 이유는 연녹 바탕 위의
/// 흰 면이 이미 경계를 만들기 때문이다 — 선을 더하면 지저분해진다.
class _HeroChip extends StatelessWidget {
  final Widget child;
  final bool tinted;
  final VoidCallback? onTap;

  const _HeroChip({required this.child, this.tinted = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 5),
      decoration: BoxDecoration(
        color: tinted ? AppColors.brandTint : AppColors.bg,
        borderRadius: AppRadius.brPill,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}
