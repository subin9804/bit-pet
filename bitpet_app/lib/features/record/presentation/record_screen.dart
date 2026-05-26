import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../../pet/providers/pet_provider.dart';
import '../providers/record_provider.dart';
import '../data/models/record_models.dart';
import '../data/record_repository.dart';

class RecordScreen extends ConsumerStatefulWidget {
  final int petId;
  final String recordType; // weight / feeding / health

  const RecordScreen({
    super.key,
    required this.petId,
    required this.recordType,
  });

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  @override
  Widget build(BuildContext context) {
    final title = switch (widget.recordType) {
      'weight' => '체중 기록',
      'feeding' => '급여 기록',
      'health' => '건강 메모',
      _ => '기록',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (widget.recordType) {
        'weight' => _WeightList(petId: widget.petId),
        'feeding' => _FeedingList(petId: widget.petId),
        'health' => _HealthList(petId: widget.petId),
        _ => const EmptyState(message: '알 수 없는 기록 유형'),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInputSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showInputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _InputSheet(
        petId: widget.petId,
        recordType: widget.recordType,
        onSaved: () {
          Navigator.pop(context);
          // Invalidate provider to refresh list
          switch (widget.recordType) {
            case 'weight':
              ref.invalidate(weightListProvider(widget.petId));
            case 'feeding':
              ref.invalidate(feedingListProvider(widget.petId));
            case 'health':
              ref.invalidate(healthMemoListProvider(widget.petId));
          }
        },
      ),
    );
  }
}

class _WeightList extends ConsumerWidget {
  final int petId;
  const _WeightList({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weightListProvider(petId));
    return async.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => EmptyState(message: e.toString()),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
              message: '체중 기록이 없어요', icon: Icons.monitor_weight_outlined);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = records[i];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monitor_weight_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.weightG.toStringAsFixed(1)}g',
                          style: AppTextStyles.bodyBold),
                      Text(
                          '${r.measuredAt.year}.${r.measuredAt.month}.${r.measuredAt.day}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                  if (r.memo != null) ...[
                    const Spacer(),
                    Flexible(
                        child: Text(r.memo!,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FeedingList extends ConsumerWidget {
  final int petId;
  const _FeedingList({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(feedingListProvider(petId));
    return async.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => EmptyState(message: e.toString()),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
              message: '급여 기록이 없어요', icon: Icons.restaurant_outlined);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = records[i];
            final responseColor = switch (r.feedResponse) {
              FeedResponse.COMPLETE => AppColors.success,
              FeedResponse.PARTIAL => AppColors.warning,
              FeedResponse.REFUSED => AppColors.error,
              null => AppColors.textSecondary,
            };
            final responseLabel = switch (r.feedResponse) {
              FeedResponse.COMPLETE => '완식',
              FeedResponse.PARTIAL => '부분',
              FeedResponse.REFUSED => '거절',
              null => '-',
            };
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_outlined,
                      color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.foodType, style: AppTextStyles.bodyBold),
                        Text(
                            '${r.fedAt.year}.${r.fedAt.month}.${r.fedAt.day}',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Text(responseLabel,
                      style: AppTextStyles.bodyBold
                          .copyWith(color: responseColor)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HealthList extends ConsumerWidget {
  final int petId;
  const _HealthList({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(healthMemoListProvider(petId));
    return async.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => EmptyState(message: e.toString()),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
              message: '건강 메모가 없어요', icon: Icons.favorite_outline);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = records[i];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                          r.symptom ?? '일반 메모',
                          style: AppTextStyles.bodyBold),
                      const Spacer(),
                      Text(
                          '${r.recordedAt.year}.${r.recordedAt.month}.${r.recordedAt.day}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                  if (r.memo != null) ...[
                    const SizedBox(height: 8),
                    Text(r.memo!, style: AppTextStyles.body),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InputSheet extends ConsumerStatefulWidget {
  final int petId;
  final String recordType;
  final VoidCallback onSaved;

  const _InputSheet({
    required this.petId,
    required this.recordType,
    required this.onSaved,
  });

  @override
  ConsumerState<_InputSheet> createState() => _InputSheetState();
}

class _InputSheetState extends ConsumerState<_InputSheet> {
  final _weightCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final _foodTypeCtrl = TextEditingController();
  final _symptomCtrl = TextEditingController();
  String _feedResponse = 'COMPLETE';
  bool _isLoading = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _memoCtrl.dispose();
    _foodTypeCtrl.dispose();
    _symptomCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(recordRepositoryProvider);
      switch (widget.recordType) {
        case 'weight':
          final w = double.tryParse(_weightCtrl.text);
          if (w == null) throw Exception('올바른 숫자를 입력하세요');
          await repo.addWeight(widget.petId, w, DateTime.now(),
              _memoCtrl.text.isEmpty ? null : _memoCtrl.text);
        case 'feeding':
          if (_foodTypeCtrl.text.isEmpty) throw Exception('먹이 종류를 입력하세요');
          await repo.addFeeding(widget.petId, {
            'foodType': _foodTypeCtrl.text,
            'feedResponse': _feedResponse,
            'fedAt': DateTime.now().toIso8601String(),
            if (_memoCtrl.text.isNotEmpty) 'memo': _memoCtrl.text,
          });
        case 'health':
          await repo.addHealthMemo(widget.petId, {
            if (_symptomCtrl.text.isNotEmpty) 'symptom': _symptomCtrl.text,
            if (_memoCtrl.text.isNotEmpty) 'memo': _memoCtrl.text,
            'recordedAt': DateTime.now().toIso8601String(),
          });
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ToastMessage.show(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.recordType == 'weight') ...[
            Text('체중 입력', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '체중 (g)', suffixText: 'g'),
              autofocus: true,
            ),
          ] else if (widget.recordType == 'feeding') ...[
            Text('급여 기록', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            TextFormField(
              controller: _foodTypeCtrl,
              decoration:
                  const InputDecoration(labelText: '먹이 종류 (귀뚜라미, 두비아 등)'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'COMPLETE', label: Text('완식')),
                ButtonSegment(value: 'PARTIAL', label: Text('부분')),
                ButtonSegment(value: 'REFUSED', label: Text('거절')),
              ],
              selected: {_feedResponse},
              onSelectionChanged: (s) =>
                  setState(() => _feedResponse = s.first),
            ),
          ] else if (widget.recordType == 'health') ...[
            Text('건강 메모', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            TextFormField(
              controller: _symptomCtrl,
              decoration: const InputDecoration(labelText: '증상 (선택)'),
              autofocus: true,
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _memoCtrl,
            decoration: const InputDecoration(labelText: '메모 (선택)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장'),
          ),
        ],
      ),
    );
  }
}
