// SCR-11: FAB 기록 바텀시트 (v3.2)
// 4단계 플로우:
//   1단계: 기록 유형 선택 (급여/청소/체중/건강)
//   2단계: 개체 선택 (복합 선택: 개별 OR 전체)
//   3단계: 상세 입력 (유형별 폼)
//   4단계: 완료 확인
// routine_id = NULL (FAB 독립 기록)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../../pet/data/models/pet_models.dart';
import '../../pet/providers/pet_provider.dart';
import '../../record/data/models/record_models.dart';
import '../../record/data/record_repository.dart';

enum _RecordType { feeding, weight, cleaning, health }

class FabRecordSheet extends ConsumerStatefulWidget {
  const FabRecordSheet({super.key});

  @override
  ConsumerState<FabRecordSheet> createState() => _FabRecordSheetState();
}

class _FabRecordSheetState extends ConsumerState<FabRecordSheet> {
  int _step = 0;
  _RecordType? _selectedType;
  final Set<int> _selectedPetIds = {};
  bool _loading = false;

  // 급여 폼
  final _foodTypeController = TextEditingController();
  FeedResponse _feedResponse = FeedResponse.COMPLETE;

  // 체중 폼
  final _weightController = TextEditingController();

  // 공통
  final _memoController = TextEditingController();

  @override
  void dispose() {
    _foodTypeController.dispose();
    _weightController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // 핸들
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (_step > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: () => setState(() => _step--),
                    padding: EdgeInsets.zero,
                  ),
                Text(_stepTitle(), style: AppTextStyles.title),
              ],
            ),
          ),
          // 단계 인디케이터
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i <= _step
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 8),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStep(),
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle() => switch (_step) {
        0 => '기록 유형 선택',
        1 => '개체 선택',
        2 => '상세 입력',
        3 => '완료',
        _ => '기록',
      };

  Widget _buildStep() => switch (_step) {
        0 => _buildTypeStep(),
        1 => _buildPetStep(),
        2 => _buildFormStep(),
        3 => _buildConfirmStep(),
        _ => const SizedBox(),
      };

  // 1단계: 기록 유형 선택
  Widget _buildTypeStep() {
    const types = [
      (_RecordType.feeding, Icons.restaurant_outlined, '급여', '먹이를 급여했어요'),
      (_RecordType.weight, Icons.monitor_weight_outlined, '체중', '몸무게를 측정했어요'),
      (_RecordType.cleaning, Icons.cleaning_services_outlined, '청소', '사육장 청소를 했어요'),
      (_RecordType.health, Icons.favorite_outline, '건강', '건강 메모를 남겨요'),
    ];
    return Column(
      children: types.map((t) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedType = t.$1;
                _step = 1;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(t.$2, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.$3, style: AppTextStyles.bodyBold),
                      Text(t.$4, style: AppTextStyles.caption),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 2단계: 개체 선택
  Widget _buildPetStep() {
    final petsAsync = ref.watch(petListProvider);
    return petsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text(e.toString()),
      data: (pets) {
        if (pets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('등록된 개체가 없어요'),
          );
        }
        return Column(
          children: [
            // 전체 선택
            _PetSelectTile(
              label: '전체 선택',
              subLabel: '${pets.length}마리 모두',
              icon: Icons.pets,
              selected: _selectedPetIds.length == pets.length,
              onTap: () {
                setState(() {
                  if (_selectedPetIds.length == pets.length) {
                    _selectedPetIds.clear();
                  } else {
                    _selectedPetIds
                      ..clear()
                      ..addAll(pets.map((p) => p.id));
                  }
                });
              },
            ),
            const Divider(height: 16),
            ...pets.map((pet) => _PetSelectTile(
                  label: pet.name,
                  subLabel: pet.speciesName,
                  icon: Icons.circle,
                  selected: _selectedPetIds.contains(pet.id),
                  onTap: () {
                    setState(() {
                      if (_selectedPetIds.contains(pet.id)) {
                        _selectedPetIds.remove(pet.id);
                      } else {
                        _selectedPetIds.add(pet.id);
                      }
                    });
                  },
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPetIds.isEmpty
                    ? null
                    : () => setState(() => _step = 2),
                child: Text('다음 (${_selectedPetIds.length}마리)'),
              ),
            ),
          ],
        );
      },
    );
  }

  // 3단계: 상세 입력
  Widget _buildFormStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedType == _RecordType.feeding) ...[
          Text('급여 종류 *', style: AppTextStyles.label),
          const SizedBox(height: 4),
          TextField(
            controller: _foodTypeController,
            decoration: const InputDecoration(hintText: '귀뚜라미, 두비아 등'),
          ),
          const SizedBox(height: 12),
          Text('먹이 반응', style: AppTextStyles.label),
          const SizedBox(height: 4),
          _FeedResponsePicker(
            value: _feedResponse,
            onChanged: (v) => setState(() => _feedResponse = v),
          ),
        ] else if (_selectedType == _RecordType.weight) ...[
          Text('몸무게 (g) *', style: AppTextStyles.label),
          const SizedBox(height: 4),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(hintText: '0.00', suffixText: 'g'),
          ),
        ] else if (_selectedType == _RecordType.cleaning) ...[
          Text('청소 정보를 메모에 남겨주세요', style: AppTextStyles.caption),
        ],
        const SizedBox(height: 12),
        Text('메모 (선택)', style: AppTextStyles.label),
        const SizedBox(height: 4),
        TextField(
          controller: _memoController,
          decoration: const InputDecoration(hintText: '특이사항을 입력하세요'),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const CircularProgressIndicator()
                : Text('${_selectedPetIds.length}마리 기록 완료'),
          ),
        ),
      ],
    );
  }

  // 4단계: 완료 확인 (submit 후)
  Widget _buildConfirmStep() {
    return Column(
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.check_circle, color: AppColors.primary, size: 64),
        const SizedBox(height: 16),
        Text('기록 완료!', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text('${_selectedPetIds.length}마리의 기록이 저장되었어요',
            style: AppTextStyles.caption),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_selectedType == _RecordType.feeding &&
        _foodTypeController.text.trim().isEmpty) {
      showToast(context, '급여 종류를 입력해주세요');
      return;
    }
    if (_selectedType == _RecordType.weight &&
        _weightController.text.trim().isEmpty) {
      showToast(context, '몸무게를 입력해주세요');
      return;
    }

    setState(() => _loading = true);
    final repo = ref.read(recordRepositoryProvider);
    final memo = _memoController.text.trim().isEmpty
        ? null
        : _memoController.text.trim();
    final now = DateTime.now();

    try {
      for (final petId in _selectedPetIds) {
        switch (_selectedType!) {
          case _RecordType.feeding:
            await repo.addFeeding(petId, {
              'foodType': _foodTypeController.text.trim(),
              'feedResponse': _feedResponse.name,
              'fedAt': now.toIso8601String(),
              if (memo != null) 'memo': memo,
            });
          case _RecordType.weight:
            final w = double.tryParse(_weightController.text.trim());
            if (w != null) {
              await repo.addWeight(petId, w, now, memo);
            }
          case _RecordType.cleaning:
            // TODO: 청소 전용 API 구현 후 연결 — 현재 건강 메모로 임시 저장
            await repo.addHealthMemo(petId, {
              'memo': '[청소]${memo != null ? ' $memo' : ''}',
              'recordedAt': now.toIso8601String(),
            });
          case _RecordType.health:
            await repo.addHealthMemo(petId, {
              if (memo != null) 'memo': memo,
              'recordedAt': now.toIso8601String(),
            });
        }
      }
      if (mounted) setState(() => _step = 3);
    } catch (e) {
      if (mounted) showToast(context, '오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _PetSelectTile extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PetSelectTile({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.primary : AppColors.border,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.body),
                Text(subLabel, style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedResponsePicker extends StatelessWidget {
  final FeedResponse value;
  final ValueChanged<FeedResponse> onChanged;

  const _FeedResponsePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      (FeedResponse.COMPLETE, '완식', Colors.green),
      (FeedResponse.PARTIAL, '부분', Colors.orange),
      (FeedResponse.REFUSED, '거절', Colors.red),
    ];
    return Row(
      children: options.map((o) {
        final selected = value == o.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(o.$2),
            selected: selected,
            selectedColor: o.$3.withValues(alpha: 0.2),
            onSelected: (_) => onChanged(o.$1),
          ),
        );
      }).toList(),
    );
  }
}
