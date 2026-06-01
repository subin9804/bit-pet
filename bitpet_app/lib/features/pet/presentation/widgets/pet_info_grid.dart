import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/pet_models.dart';

class PetInfoGrid extends StatelessWidget {
  final Pet pet;

  const PetInfoGrid({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final hatch = pet.hatchingDate;
    final adopt = pet.adoptionDate;
    final age   = _ageString(hatch);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          // 2열 그리드
          Row(
            children: [
              _Cell(label: '모프',   value: pet.morphName ?? '-'),
              const SizedBox(width: 12),
              _Cell(label: '해칭일', value: _fmtDate(hatch), mono: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Cell(label: '입양일', value: _fmtDate(adopt), mono: true),
              const SizedBox(width: 12),
              _Cell(label: '나이',   value: age),
            ],
          ),
          const SizedBox(height: 12),
          // 부모 (전체폭)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('부모', style: AppTextStyles.paleGridLabel),
              const SizedBox(height: 3),
              Text(
                '등록된 부모 개체 없음',
                style: AppTextStyles.paleGridValue.copyWith(
                    color: AppColors.paleInk2, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _ageString(DateTime? hatch) {
    if (hatch == null) return '-';
    final now  = DateTime.now();
    int months = (now.year - hatch.year) * 12 + now.month - hatch.month;
    if (months < 0) return '-';
    final y = months ~/ 12;
    final m = months % 12;
    if (y == 0) return '$m개월';
    if (m == 0) return '$y년';
    return '$y년 $m개월';
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _Cell({required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.paleGridLabel),
          const SizedBox(height: 3),
          Text(
            value,
            style: mono
                ? AppTextStyles.mono(13, FontWeight.w600)
                : AppTextStyles.paleGridValue,
          ),
        ],
      ),
    );
  }
}
