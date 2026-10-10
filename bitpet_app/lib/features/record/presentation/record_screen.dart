import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../../../core/theme/app_input_styles.dart';
import '../providers/record_invalidation.dart';
import '../providers/record_provider.dart';
import '../data/models/record_models.dart';
import '../data/record_repository.dart';
import 'widgets/feed_composer_fields.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_dimens.dart';

class RecordScreen extends ConsumerStatefulWidget {
  final int petId;
  final String recordType; // weight / feeding / cleaning / memo

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
      'weight'   => '체중 기록',
      'feeding'  => '급여 기록',
      'cleaning' => '청소 기록',
      'memo'     => '메모',
      'mating'   => '교배 기록',
      'laying'   => '산란 기록',
      _ => '기록',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // ⛔ 이 ＋ 를 다시 FAB 으로 내리지 말 것. 하단 내비 중앙에 기록 ＋ 가
        // 있어서, 떠 있는 FAB 은 **그 바로 위에 겹쳐 ＋ 가 세로로 두 개**가 된다.
        // 이쪽 ＋ 는 "이 종류의 기록"을 바로 여는 것이라 뜻도 다르다.
        actions: [
          IconButton(
            tooltip: '기록 추가',
            icon: const Icon(Icons.add),
            onPressed: () => _showInputSheet(context),
          ),
        ],
      ),
      body: switch (widget.recordType) {
        'weight'   => _WeightList(petId: widget.petId),
        'feeding'  => _FeedingList(petId: widget.petId),
        'cleaning' => _CleaningList(petId: widget.petId),
        'memo'     => _MemoList(petId: widget.petId),
        'mating'   => _MatingList(petId: widget.petId),
        'laying'   => _LayingList(petId: widget.petId),
        _ => const EmptyState(message: '알 수 없는 기록 유형'),
      },
    );
  }

  void _showInputSheet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (_) => _InputSheet(
        petId: widget.petId,
        recordType: widget.recordType,
        onSaved: () {
          Navigator.pop(context);
          invalidatePetRecords(ref, widget.petId);
        },
      ),
    );
  }
}

// ── 체중 목록 ─────────────────────────────────────────────────

class _WeightList extends ConsumerWidget {
  final int petId;
  const _WeightList({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weightListProvider(petId));
    return async.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => const EmptyState(
          message: '불러오지 못했어요',
          subMessage: '연결을 확인하고 당겨서 새로고침해 주세요.',
          icon: Icons.cloud_off,
          tone: EmptyTone.neutral),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
              message: '체중 기록이 없어요',
              subMessage: '오른쪽 위 ＋ 로 첫 기록을 남겨 보세요.',
              icon: Icons.monitor_weight_outlined);
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
                borderRadius: AppRadius.brLg,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const AppIcon(AppIcons.weight,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.weightG.toStringAsFixed(1)}g',
                          style: AppTextStyles.bodyBold),
                      Text(
                          '${r.measuredAt.toLocal().year}.${r.measuredAt.toLocal().month}.${r.measuredAt.toLocal().day}',
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

// ── 급여 목록 ─────────────────────────────────────────────────

class _FeedingList extends ConsumerWidget {
  final int petId;
  const _FeedingList({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(feedingListProvider(petId));
    return async.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => const EmptyState(
          message: '불러오지 못했어요',
          subMessage: '연결을 확인하고 당겨서 새로고침해 주세요.',
          icon: Icons.cloud_off,
          tone: EmptyTone.neutral),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
              message: '급여 기록이 없어요',
              subMessage: '오른쪽 위 ＋ 로 첫 기록을 남겨 보세요.',
              icon: Icons.restaurant_outlined);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = records[i];
            final parts = <String>[];
            if (r.sizeLabel != null) parts.add(r.sizeLabel!);
            if (r.amount != null) {
              final u = r.unit == 'PIECE' ? '마리' : (r.unit ?? '');
              parts.add('${r.amount!.toStringAsFixed(r.amount! % 1 == 0 ? 0 : 1)}$u');
            }
            final foodLabel =
                r.foodType == null ? '거식' : FoodType.labelForCode(r.foodType!);
            final subtitle = (r.refused || parts.isEmpty)
                ? foodLabel
                : '$foodLabel · ${parts.join(' ')}';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.brLg,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const AppIcon(AppIcons.feeding,
                      color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subtitle, style: AppTextStyles.bodyBold),
                        Text(
                            '${r.fedAt.toLocal().year}.${r.fedAt.toLocal().month}.${r.fedAt.toLocal().day}',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── 청소 목록 ─────────────────────────────────────────────────

class _CleaningList extends ConsumerWidget {
  final int petId;
  const _CleaningList({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cleaningListProvider(petId));
    return async.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => const EmptyState(
          message: '불러오지 못했어요',
          subMessage: '연결을 확인하고 당겨서 새로고침해 주세요.',
          icon: Icons.cloud_off,
          tone: EmptyTone.neutral),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
              message: '청소 기록이 없어요',
              subMessage: '오른쪽 위 ＋ 로 첫 기록을 남겨 보세요.',
              icon: Icons.cleaning_services_outlined);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = records[i];
            final typeLabel = switch (r.cleaningType) {
              CleaningType.FULL => '전체 청소',
              CleaningType.PARTIAL => '부분 청소',
              CleaningType.WATER_CHANGE => '물 교체',
            };
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.brLg,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const AppIcon(AppIcons.cleaning,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(typeLabel, style: AppTextStyles.bodyBold),
                        Text(
                            '${r.cleanedAt.year}.${r.cleanedAt.month}.${r.cleanedAt.day}',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (r.memo != null)
                    Flexible(
                        child: Text(r.memo!,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── 메모 목록 (v5) ────────────────────────────────────────────

class _MemoList extends ConsumerWidget {
  final int petId;
  const _MemoList({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(memoListProvider(petId));
    return async.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => const EmptyState(
          message: '불러오지 못했어요',
          subMessage: '연결을 확인하고 당겨서 새로고침해 주세요.',
          icon: Icons.cloud_off,
          tone: EmptyTone.neutral),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
              message: '메모가 없어요',
              subMessage: '오른쪽 위 ＋ 로 첫 메모를 남겨 보세요.',
              icon: Icons.note_alt_outlined);
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
                borderRadius: AppRadius.brLg,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppIcon(AppIcons.memo,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      if (r.tags.isNotEmpty)
                        Text(r.tags.join(', '),
                            style: AppTextStyles.bodyBold),
                      const Spacer(),
                      Text(
                          '${r.loggedAt.toLocal().year}.${r.loggedAt.toLocal().month}.${r.loggedAt.toLocal().day}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(r.displayContent, style: AppTextStyles.body),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── 교배 목록 ─────────────────────────────────────────────────

class _MatingList extends ConsumerWidget {
  final int petId;
  const _MatingList({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(matingListProvider(petId));
    return async.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => const EmptyState(
          message: '불러오지 못했어요',
          subMessage: '연결을 확인하고 당겨서 새로고침해 주세요.',
          icon: Icons.cloud_off,
          tone: EmptyTone.neutral),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
              message: '교배 기록이 없어요',
              subMessage: '오른쪽 위 ＋ 로 첫 기록을 남겨 보세요.',
              icon: Icons.favorite_outline);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = records[i];
            final dateStr =
                '${r.triedAt.year}.${r.triedAt.month}.${r.triedAt.day}';
            final resultLabel = r.isSuccessful == true
                ? '성공'
                : r.isSuccessful == false
                    ? '실패'
                    : '결과 미정';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.brLg,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const AppIcon(AppIcons.likeLine, color: AppColors.female),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr, style: AppTextStyles.bodyBold),
                        Text(resultLabel, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (r.memo != null)
                    Flexible(
                        child: Text(r.memo!,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── 산란 목록 ─────────────────────────────────────────────────

class _LayingList extends ConsumerWidget {
  final int petId;
  const _LayingList({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(layingListProvider(petId));
    return async.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => const EmptyState(
          message: '불러오지 못했어요',
          subMessage: '연결을 확인하고 당겨서 새로고침해 주세요.',
          icon: Icons.cloud_off,
          tone: EmptyTone.neutral),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
              message: '산란 기록이 없어요',
              subMessage: '오른쪽 위 ＋ 로 첫 기록을 남겨 보세요.',
              icon: Icons.egg_outlined);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = records[i];
            final dateStr =
                '${r.laidAt.year}.${r.laidAt.month}.${r.laidAt.day}';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.brLg,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const AppIcon(AppIcons.laying, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${r.totalCount}개 · $dateStr',
                            style: AppTextStyles.bodyBold),
                        if (r.hatches.isNotEmpty)
                          Text('부화 ${r.hatches.length}건',
                              style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (r.memo != null)
                    Flexible(
                        child: Text(r.memo!,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── 입력 시트 ─────────────────────────────────────────────────

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
  final _contentCtrl = TextEditingController();
  final _countCtrl = TextEditingController();
  FeedFormData _feedForm = const FeedFormData();
  CleaningType _cleaningType = CleaningType.FULL;
  bool? _matingSuccess;
  bool _isLoading = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _memoCtrl.dispose();
    _contentCtrl.dispose();
    _countCtrl.dispose();
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
          if (!_feedForm.isValid) throw Exception('급여 종류를 선택하세요');
          await repo.addFeeding(widget.petId, _feedForm.toApiMap(fedAt: DateTime.now()));
        case 'cleaning':
          await repo.addCleaning(
              widget.petId,
              _cleaningType,
              DateTime.now(),
              _memoCtrl.text.isEmpty ? null : _memoCtrl.text);
        case 'memo':
          if (_contentCtrl.text.trim().isEmpty) throw Exception('내용을 입력하세요');
          await repo.addMemo(widget.petId, {
            'content': _contentCtrl.text.trim(),
            'loggedAt': DateTime.now().toUtc().toIso8601String(),
          });
        case 'mating':
          await repo.addMating(widget.petId, {
            'triedAt': DateTime.now().toUtc().toIso8601String(),
            if (_matingSuccess != null) 'isSuccessful': _matingSuccess,
            if (_memoCtrl.text.isNotEmpty) 'memo': _memoCtrl.text,
          });
        case 'laying':
          final cnt = int.tryParse(_countCtrl.text);
          if (cnt == null || cnt <= 0) throw Exception('산란 수를 입력하세요');
          await repo.addLaying(widget.petId, {
            'laidAt': DateTime.now().toUtc().toIso8601String(),
            'totalCount': cnt,
            if (_memoCtrl.text.isNotEmpty) 'memo': _memoCtrl.text,
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

  /// 기록 종류 이름은 시트 제목(AppSheet 슬롯 2)이 맡는다 —
  /// 본문 첫 줄에 같은 말을 또 쓰지 않는다.
  String get _title => switch (widget.recordType) {
        'weight' => '체중 입력',
        'feeding' => '급여 기록',
        'cleaning' => '청소 기록',
        'memo' => '메모 작성',
        'mating' => '교배 기록',
        'laying' => '산란 기록',
        _ => '기록 추가',
      };

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: _title,
      busy: _isLoading,
      primaryLabel: '저장',
      onPrimary: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.recordType == 'weight') ...[
            TextFormField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: '체중 (g)', suffixText: 'g'),
              autofocus: true,
            ),
          ] else if (widget.recordType == 'feeding') ...[
            FeedComposerFields(
              form: _feedForm,
              onChanged: (f) => setState(() => _feedForm = f),
              showMemo: false,
            ),
          ] else if (widget.recordType == 'cleaning') ...[
            SegmentedButton<CleaningType>(
              segments: const [
                ButtonSegment(value: CleaningType.FULL, label: Text('전체')),
                ButtonSegment(value: CleaningType.PARTIAL, label: Text('부분')),
                ButtonSegment(
                    value: CleaningType.WATER_CHANGE, label: Text('물교체')),
              ],
              selected: {_cleaningType},
              onSelectionChanged: (s) =>
                  setState(() => _cleaningType = s.first),
            ),
          ] else if (widget.recordType == 'memo') ...[
            TextFormField(
              controller: _contentCtrl,
              decoration: AppInputStyles.textarea(hintText: '내용 *'),
              maxLines: 3,
              autofocus: true,
            ),
          ] else if (widget.recordType == 'mating') ...[
            SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(value: null,  label: Text('미정')),
                ButtonSegment(value: true,  label: Text('성공')),
                ButtonSegment(value: false, label: Text('실패')),
              ],
              selected: {_matingSuccess},
              onSelectionChanged: (s) =>
                  setState(() => _matingSuccess = s.first),
            ),
          ] else if (widget.recordType == 'laying') ...[
            TextFormField(
              controller: _countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '산란 수 *', suffixText: '개'),
              autofocus: true,
            ),
          ],
          const SizedBox(height: 12),
          if (widget.recordType != 'memo' && widget.recordType != 'feeding')
            TextFormField(
              controller: _memoCtrl,
              decoration: const InputDecoration(labelText: '메모 (선택)'),
            ),
        ],
      ),
    );
  }
}
