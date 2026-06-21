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
    final precision = pet.hatchingDatePrecision;
    final approx = pet.hatchingDateApproximate;
    final adopt = pet.adoptionDate;
    final age   = _ageString(hatch, precision, approx);

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
              _Cell(
                label: '해칭일',
                value: _fmtDate(hatch, precision),
                mono: true,
                chip: approx ? '부정확' : null,
              ),
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

  String _fmtDate(DateTime? d, [String precision = 'DAY']) {
    if (d == null) return '-';
    return precision == 'MONTH'
        ? '${d.year}.${d.month.toString().padLeft(2, '0')}'
        : '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  String _ageString(DateTime? hatch, [String precision = 'DAY', bool approx = false]) {
    if (hatch == null) return '-';
    // MONTH 정밀도인 경우 해당 월 15일로 추정
    final effective = precision == 'MONTH'
        ? DateTime(hatch.year, hatch.month, 15)
        : hatch;
    final now = DateTime.now();
    int months = (now.year - effective.year) * 12 + now.month - effective.month;
    if (months < 0) return '-';
    final y = months ~/ 12;
    final m = months % 12;
    final base = y == 0 ? '$m개월' : m == 0 ? '$y년' : '$y년 $m개월';
    return approx ? '약 $base' : base;
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final String? chip;

  const _Cell({required this.label, required this.value, this.mono = false, this.chip});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.paleGridLabel),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: mono
                      ? AppTextStyles.mono(13, FontWeight.w600)
                      : AppTextStyles.paleGridValue,
                ),
              ),
              if (chip != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.petPeach,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    chip!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.petPeachInk,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
