import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/pet_models.dart';
import '../providers/pet_provider.dart';

/// 남의 공개 개체 화면 — 가계도 카드에서 공개 개체를 눌렀을 때.
///
/// 내 개체 상세(`/pets/:id`)와 **다른 화면**인 이유: 저쪽은 체중·급여·메모 탭이 붙은
/// 사육 화면이다. 남의 개체에는 그 기록이 없고 있어서도 안 된다 — 서버도 [PetCard]
/// 필드만 내려준다. 비공개 개체는 서버가 404로 뭉개므로 여기까지 오지 않는다.
class PublicPetScreen extends ConsumerWidget {
  final int petId;
  const PublicPetScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicPetProvider(petId));

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      appBar: AppBar(
        backgroundColor: AppColors.paleBg,
        elevation: 0,
        title: const Text('개체 정보',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('개체 정보를 불러오지 못했어요',
              style: TextStyle(fontSize: 13, color: AppColors.paleInk3)),
        ),
        data: (card) => _Body(card: card),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final PetCard card;
  const _Body({required this.card});

  Color get _identityColor {
    if (card.colorCode == null) return AppColors.bg2;
    try {
      return Color(int.parse(card.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.bg2;
    }
  }

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
    final owner = card.owner;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: _identityColor,
            border: Border.all(color: AppColors.paleLine),
          ),
          clipBehavior: Clip.hardEdge,
          child: card.profileImageUrl != null
              ? Image.network(card.profileImageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                      child: Text('🦎', style: TextStyle(fontSize: 48))))
              : const Center(child: Text('🦎', style: TextStyle(fontSize: 48))),
        ),
        const SizedBox(height: 14),
        Text(card.name,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.4)),
        const SizedBox(height: 4),
        // 소유자 — 본인 개체면 줄 자체를 없앤다 (가계도 카드와 같은 규칙)
        if (!owner.isMe)
          owner.isOrphaned || owner.userId == null
              ? const Text('정보 없음',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic))
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/users/${owner.userId}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('@${owner.nickname ?? ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ),
        const SizedBox(height: 18),
        _Row(label: '일련번호', value: card.serialNo.isEmpty ? '-' : card.serialNo),
        _Row(label: '종', value: card.speciesName.isEmpty ? '-' : card.speciesName),
        _Row(label: '모프', value: card.morphLabel.isEmpty ? '-' : card.morphLabel),
        _Row(label: '성별', value: _genderLabel),
        _Row(label: '해칭일', value: _hatchLabel),
        if (card.isDeceased) const _Row(label: '상태', value: '이별한 개체 🕊'),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
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
