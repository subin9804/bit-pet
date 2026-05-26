// SCR-12: 루틴 완료 모달 (v3.2 신규)
// 1단계: 일괄/개별 분기 (2마리 이상일 때)
// 2단계-A: 일괄 입력 (단일 폼)
// 2단계-B: 개별 입력 (카드 슬라이더)
// 입력 폼 컴포넌트는 SCR-11 (FAB 기록 바텀시트)과 공유 예정
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';

class RoutineCompleteModal extends ConsumerStatefulWidget {
  final Routine routine;

  const RoutineCompleteModal({super.key, required this.routine});

  @override
  ConsumerState<RoutineCompleteModal> createState() =>
      _RoutineCompleteModalState();
}

class _RoutineCompleteModalState extends ConsumerState<RoutineCompleteModal> {
  // 0: 분기 선택, 1: 일괄 입력, 2: 개별 카드 슬라이더
  int _step = 0;
  bool _loading = false;

  // 일괄/개별 폼 컨트롤러 (타입별 필드)
  final _memoController = TextEditingController();
  final _foodTypeController = TextEditingController();
  String _cleaningType = 'FULL';
  String _feedResponse = 'COMPLETE';
  int _currentCardIndex = 0;

  bool get _isSinglePet => widget.routine.petCount <= 1;

  @override
  void initState() {
    super.initState();
    // 1마리면 분기 없이 바로 일괄 입력
    if (_isSinglePet) _step = 1;
  }

  @override
  void dispose() {
    _memoController.dispose();
    _foodTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routine = widget.routine;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
          // 제목
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(routine.title, style: AppTextStyles.title),
                Text(
                  '${routine.petCount}마리 연결됨',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _buildBranchStep(),
      1 => _buildBatchInputStep(),
      2 => _buildIndividualSliderStep(),
      _ => const SizedBox(),
    };
  }

  // 1단계: 일괄/개별 분기
  Widget _buildBranchStep() {
    return Column(
      children: [
        Text('어떻게 입력하시겠어요?', style: AppTextStyles.bodyBold),
        const SizedBox(height: 16),
        _BranchButton(
          icon: Icons.inventory_2_outlined,
          label: '일괄 입력',
          description: '모두 같은 정보로',
          onTap: () => setState(() => _step = 1),
        ),
        const SizedBox(height: 12),
        _BranchButton(
          icon: Icons.view_carousel_outlined,
          label: '개별 입력',
          description: '개체별로 다르게 입력',
          onTap: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  // 2단계-A: 일괄 입력
  Widget _buildBatchInputStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('일괄 입력', style: AppTextStyles.bodyBold),
        const SizedBox(height: 16),
        _buildTypeSpecificForm(widget.routine.routineType),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submitBatch,
            child: _loading
                ? const CircularProgressIndicator()
                : Text('${widget.routine.petCount}마리 완료'),
          ),
        ),
      ],
    );
  }

  // 2단계-B: 개별 카드 슬라이더
  Widget _buildIndividualSliderStep() {
    final petIds = widget.routine.petIds;
    if (petIds.isEmpty) return const SizedBox();

    return Column(
      children: [
        Text(
          '${_currentCardIndex + 1}/${petIds.length}',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 8),
        // TODO: 개체 이름 표시 (petId로 개체 정보 조회 필요)
        Text('Pet ID: ${petIds[_currentCardIndex]}',
            style: AppTextStyles.bodyBold),
        const SizedBox(height: 16),
        _buildTypeSpecificForm(widget.routine.routineType),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : () => _submitIndividual(
                    petIds[_currentCardIndex], RoutineLogStatus.COMPLETED),
                child: const Text('완료'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : () => _submitIndividual(
                    petIds[_currentCardIndex], RoutineLogStatus.REFUSED),
                child: const Text('미완료'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 타입별 입력 폼 (SCR-11과 공유 예정)
  Widget _buildTypeSpecificForm(RoutineType type) {
    return switch (type) {
      RoutineType.FEEDING => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 12),
            _MemoField(controller: _memoController),
          ],
        ),
      RoutineType.CLEANING => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('청소 유형', style: AppTextStyles.label),
            const SizedBox(height: 4),
            _CleaningTypePicker(
              value: _cleaningType,
              onChanged: (v) => setState(() => _cleaningType = v),
            ),
            const SizedBox(height: 12),
            _MemoField(controller: _memoController),
          ],
        ),
      RoutineType.WEIGHT => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('몸무게 (g) *', style: AppTextStyles.label),
            const SizedBox(height: 4),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0.00', suffixText: 'g'),
            ),
            const SizedBox(height: 12),
            _MemoField(controller: _memoController),
          ],
        ),
      RoutineType.CUSTOM => _MemoField(controller: _memoController),
    };
  }

  Future<void> _submitBatch() async {
    setState(() => _loading = true);
    try {
      final req = RoutineCompleteBatchRequest(
        foodType: widget.routine.routineType == RoutineType.FEEDING
            ? _foodTypeController.text.trim()
            : null,
        cleaningType: widget.routine.routineType == RoutineType.CLEANING
            ? _cleaningType
            : null,
        feedResponse: widget.routine.routineType == RoutineType.FEEDING
            ? _feedResponse
            : null,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
      );
      await ref.read(routineRepositoryProvider)
          .completeBatch(widget.routine.id, req);
      ref.invalidate(routineListProvider);
      if (mounted) {
        Navigator.of(context).pop();
        showToast(context, '${widget.routine.petCount}마리 완료!');
      }
    } catch (e) {
      if (mounted) showToast(context, '오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitIndividual(int petId, RoutineLogStatus status) async {
    // REFUSED + 메모 없으면 저장 안 함
    if (status == RoutineLogStatus.REFUSED &&
        _memoController.text.trim().isEmpty) {
      _nextCard();
      return;
    }
    setState(() => _loading = true);
    try {
      final req = RoutineCompleteIndividualRequest(
        petId: petId,
        status: status,
        foodType: widget.routine.routineType == RoutineType.FEEDING
            ? _foodTypeController.text.trim()
            : null,
        cleaningType: widget.routine.routineType == RoutineType.CLEANING
            ? _cleaningType
            : null,
        feedResponse: widget.routine.routineType == RoutineType.FEEDING
            ? _feedResponse
            : null,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
      );
      await ref.read(routineRepositoryProvider)
          .completeIndividual(widget.routine.id, req);
      _memoController.clear();
      _foodTypeController.clear();
      _nextCard();
    } catch (e) {
      if (mounted) showToast(context, '오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _nextCard() {
    final petIds = widget.routine.petIds;
    if (_currentCardIndex < petIds.length - 1) {
      setState(() => _currentCardIndex++);
    } else {
      ref.invalidate(routineListProvider);
      Navigator.of(context).pop();
    }
  }
}

// ---------------------------------------------------------------------------
// 공유 위젯
// ---------------------------------------------------------------------------

class _BranchButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _BranchButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyBold),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _MemoField extends StatelessWidget {
  final TextEditingController controller;
  const _MemoField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(hintText: '메모 (선택)'),
      maxLines: 2,
    );
  }
}

class _FeedResponsePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FeedResponsePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      ('COMPLETE', '완식', Colors.green),
      ('PARTIAL', '부분', Colors.orange),
      ('REFUSED', '거절', Colors.red),
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

class _CleaningTypePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CleaningTypePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      ('FULL', '전체', Colors.green),
      ('PARTIAL', '부분', Colors.orange),
      ('WATER_CHANGE', '물 갈기', Colors.blue),
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
