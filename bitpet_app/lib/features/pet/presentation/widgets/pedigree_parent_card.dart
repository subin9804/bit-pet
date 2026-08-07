import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/pet_models.dart';

/// 가계도 부모 카드 — 좌측 썸네일 + 우측 2줄.
///
/// 부모는 **소유자와 무관하게** 걸 수 있고 승인·차단 절차가 없다. 대신 남의 개체라는 사실을
/// 소유자 줄로 드러내서 사칭을 억제한다 — 그래서 이 카드의 1줄은 장식이 아니라 정책의 일부다.
///
/// 두 줄은 **탭 타겟이 서로 겹치지 않는다**:
///   1줄(소유자) → 프로필 이동 / 2줄(개체명) → 개체 상세 또는 최소 정보 시트.
/// 썸네일은 어느 쪽에도 속하지 않는 순수 표시 영역이다 (두 줄에 걸쳐 있어 어디로 가야 할지
/// 애매해진다).
///
/// [isMe]인 개체는 소유자 줄을 **아예 그리지 않는다**. 대부분이 본인 개체라 매번 내 닉네임이
/// 붙으면 노이즈일 뿐이고, 반대로 "유저명이 보인다 = 남의 개체"라는 신호가 사라진다.
class PedigreeParentCard extends StatelessWidget {
  final PetCard card;

  const PedigreeParentCard({super.key, required this.card});

  Color get _identityColor {
    if (card.colorCode == null) return AppColors.bg2;
    try {
      return Color(int.parse(card.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.bg2;
    }
  }

  void _openPet(BuildContext context) {
    if (card.isKeeper) {
      // 내가 사육하는 개체(소유자 또는 공유받은 KEEPER) — 기록까지 있는 전체 상세
      context.push('/pets/${card.petId}');
    } else if (card.canOpenDetail) {
      // 남의 공개 개체 — 사육 기록이 빠진 공개 화면
      context.push('/pets/${card.petId}/public');
    } else {
      // 비공개 개체. 서버가 상세를 내주지 않으므로 이 카드에 담긴 것만 보여준다
      showPetCardSheet(context, card);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = card.owner;
    final showOwnerLine = !owner.isMe;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Thumbnail(url: card.profileImageUrl, color: _identityColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showOwnerLine) ...[
                  _OwnerLine(owner: owner),
                  const SizedBox(height: 2),
                ],
                // 2줄 — 개체명. 탭 타겟은 이 줄에만 걸린다
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openPet(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.isFather ? '♂' : '♀',
                          style: TextStyle(
                            fontSize: 13,
                            color: card.isFather
                                ? AppColors.male
                                : AppColors.female,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            card.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (card.isDeceased) ...[
                          const SizedBox(width: 5),
                          const Text('🕊',
                              style: TextStyle(fontSize: 11)),
                        ],
                      ],
                    ),
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

/// 1줄 — 소유자. isMe면 이 위젯 자체가 만들어지지 않는다.
class _OwnerLine extends StatelessWidget {
  final PetOwner owner;
  const _OwnerLine({required this.owner});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, color: AppColors.textSecondary);

    // 탈퇴 익명화 — 갈 곳이 없으니 탭 불가. 개체명은 2줄에 그대로 남는다
    if (owner.isOrphaned || owner.userId == null) {
      return const Text('정보 없음',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ));
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/users/${owner.userId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text('@${owner.nickname ?? ''}',
            style: style, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;
  final Color color;
  const _Thumbnail({required this.url, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.paleLine),
      ),
      clipBehavior: Clip.hardEdge,
      child: url != null
          ? Image.network(url!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _ThumbFallback())
          : const _ThumbFallback(),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('🦎', style: TextStyle(fontSize: 20)));
}

/// 비공개 개체용 최소 정보 시트 — 개체명·종·모프·성별·해칭일이 전부다.
///
/// 상세로 못 들어가는 개체라 여기서 보여주는 것 이상은 서버도 내려주지 않는다
/// (사육 기록·메모·체중은 애초에 [PetCard]에 없다).
Future<void> showPetCardSheet(BuildContext context, PetCard card) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _PetCardSheet(card: card),
  );
}

class _PetCardSheet extends StatelessWidget {
  final PetCard card;
  const _PetCardSheet({required this.card});

  String get _genderLabel => switch (card.gender) {
        'MALE' => '수컷 ♂',
        'FEMALE' => '암컷 ♀',
        _ => '미구분',
      };

  String get _hatchLabel {
    final d = card.hatchingDate;
    if (d == null) return '-';
    final base = card.hatchingDatePrecision == 'MONTH'
        ? '${d.year}.${d.month.toString().padLeft(2, '0')}'
        : '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return card.hatchingDateApproximate ? '$base (부정확)' : base;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 16),
              decoration: BoxDecoration(
                  color: AppColors.paleLine,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRIVATE',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.paleInk2,
                          letterSpacing: 0.4)),
                  const SizedBox(height: 3),
                  Text(card.name,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: -0.4)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
              child: Column(
                children: [
                  _SheetRow(label: '종', value: card.speciesName.isEmpty ? '-' : card.speciesName),
                  _SheetRow(label: '모프', value: card.morphLabel.isEmpty ? '-' : card.morphLabel),
                  _SheetRow(label: '성별', value: _genderLabel),
                  _SheetRow(label: '해칭일', value: _hatchLabel),
                  const SizedBox(height: 14),
                  const Text(
                    '비공개 개체라 여기까지만 볼 수 있어요',
                    style: TextStyle(fontSize: 12, color: AppColors.paleInk3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  const _SheetRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.paleInk3)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
